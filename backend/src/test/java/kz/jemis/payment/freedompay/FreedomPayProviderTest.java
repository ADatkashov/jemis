package kz.jemis.payment.freedompay;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import kz.jemis.common.ApiException;
import kz.jemis.order.Order;
import kz.jemis.payment.Payment;
import kz.jemis.payment.PaymentProvider;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class FreedomPayProviderTest {
    private static final String SECRET = "test-secret";
    private static final String NOTIFY = "result.php";

    private HttpServer server;
    private final AtomicReference<String> lastPath = new AtomicReference<>();
    private final AtomicReference<String> lastBody = new AtomicReference<>();

    @AfterEach
    void stop() {
        if (server != null) server.stop(0);
    }

    private FreedomPayProvider provider(String apiUrl) {
        return new FreedomPayProvider(true, apiUrl, "m1", SECRET, NOTIFY, "https://app.example/ok", "https://app.example/fail");
    }

    /** Starts a fake Freedom Pay that answers every POST with the given XML body. */
    private String fakeApi(String xml) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", ex -> {
            lastPath.set(ex.getRequestURI().getPath());
            lastBody.set(new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            byte[] out = xml.getBytes(StandardCharsets.UTF_8);
            ex.sendResponseHeaders(200, out.length);
            ex.getResponseBody().write(out);
            ex.close();
        });
        server.start();
        return "http://127.0.0.1:" + server.getAddress().getPort();
    }

    private static Order order() {
        Order o = new Order();
        o.setNumber("JM-100010");
        return o;
    }

    private static Payment payment(long minor) {
        Payment p = new Payment();
        p.setAmountMinor(minor);
        p.setCurrency("KZT");
        p.setProviderRef("fp-777");
        return p;
    }

    private static byte[] signedForm(Map<String, String> fields, String script, String secret) {
        Map<String, String> all = new LinkedHashMap<>(fields);
        all.put("pg_sig", FreedomPaySignature.compute(script, fields, secret));
        StringBuilder sb = new StringBuilder();
        all.forEach((k, v) -> sb.append(sb.length() == 0 ? "" : "&").append(URLEncoder.encode(k, StandardCharsets.UTF_8))
                .append('=').append(URLEncoder.encode(v, StandardCharsets.UTF_8)));
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    private static Map<String, String> notification(String result, String amount) {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("pg_order_id", "JM-100010-ab12cd34");
        f.put("pg_payment_id", "fp-777");
        f.put("pg_amount", amount);
        f.put("pg_currency", "KZT");
        f.put("pg_result", result);
        f.put("pg_salt", "abc");
        return f;
    }

    // ---- configuration ----

    @Test
    void disabledProviderNeedsNoConfigAndRejectsWebhooks() {
        FreedomPayProvider p = new FreedomPayProvider(false, "", "", "", "", "", "");
        assertFalse(p.isEnabled());
        assertEquals("freedompay", p.key());
        assertFalse(p.developmentOnly());
        ApiException e = assertThrows(ApiException.class, () -> p.verifyAndParse(Map.of(), new byte[0]));
        assertEquals("INVALID_SIGNATURE", e.code());
    }

    @Test
    void enabledProviderFailsAtStartupWhenConfigIsIncomplete() {
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "", "m", "s", NOTIFY, "https://a", "https://b"));
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "https://api", "", "s", NOTIFY, "https://a", "https://b"));
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "https://api", "m", "", NOTIFY, "https://a", "https://b"));
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "https://api", "m", "s", "", "https://a", "https://b"));
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "https://api", "m", "s", NOTIFY, "", "https://b"));
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "https://api", "m", "s", NOTIFY, "https://a", ""));
    }

    @Test
    void apiUrlMustBeHttpsExceptForLoopback() {
        assertThrows(IllegalStateException.class, () -> new FreedomPayProvider(true, "http://api.example.com", "m", "s", NOTIFY, "https://a", "https://b"));
        new FreedomPayProvider(true, "https://api.example.com/", "m", "s", NOTIFY, "https://a", "https://b");
        new FreedomPayProvider(true, "http://localhost:9999", "m", "s", NOTIFY, "https://a", "https://b");
    }

    // ---- webhook ----

    @Test
    void validPaidNotificationBecomesSucceededEventWithAmountInTiyn() {
        PaymentProvider.Event ev = provider("https://api.example.com").verifyAndParse(Map.of(),
                signedForm(notification("1", "5450.00"), NOTIFY, SECRET));
        assertEquals(PaymentProvider.EventType.SUCCEEDED, ev.type());
        assertEquals("fp-777", ev.providerRef());
        assertEquals("fp-777:1", ev.eventId());
        assertEquals(545000L, ev.amountMinor());
        assertNull(ev.failureReason());
    }

    @Test
    void failedNotificationCarriesTheReason() {
        Map<String, String> f = notification("0", "100.00");
        f.put("pg_failure_description", "Card declined");
        PaymentProvider.Event ev = provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(f, NOTIFY, SECRET));
        assertEquals(PaymentProvider.EventType.FAILED, ev.type());
        assertEquals("Card declined", ev.failureReason());
        assertEquals("fp-777:0", ev.eventId());
    }

    @Test
    void failedNotificationFallsBackToErrorDescription() {
        Map<String, String> f = notification("0", "100.00");
        f.put("pg_error_description", "Timeout");
        assertEquals("Timeout", provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(f, NOTIFY, SECRET)).failureReason());
        assertNull(provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(notification("0", "1.00"), NOTIFY, SECRET)).failureReason());
    }

    @Test
    void wrongSignatureOrWrongSecretOrMissingSignatureIsRejectedWith401() {
        FreedomPayProvider p = provider("https://api.example.com");
        for (byte[] body : new byte[][] {
                signedForm(notification("1", "5450.00"), NOTIFY, "other-secret"),
                signedForm(notification("1", "5450.00"), "other.php", SECRET),
                "pg_payment_id=fp-777&pg_result=1".getBytes(StandardCharsets.UTF_8) }) {
            ApiException e = assertThrows(ApiException.class, () -> p.verifyAndParse(Map.of(), body));
            assertEquals(HttpStatus.UNAUTHORIZED, e.status());
            assertEquals("INVALID_SIGNATURE", e.code());
        }
    }

    @Test
    void tamperedAmountInvalidatesTheSignature() {
        byte[] good = signedForm(notification("1", "5450.00"), NOTIFY, SECRET);
        byte[] tampered = new String(good, StandardCharsets.UTF_8).replace("5450.00", "1.00").getBytes(StandardCharsets.UTF_8);
        assertThrows(ApiException.class, () -> provider("https://api.example.com").verifyAndParse(Map.of(), tampered));
    }

    @Test
    void signedNotificationWithoutPaymentIdIsMalformed() {
        Map<String, String> f = notification("1", "5450.00");
        f.remove("pg_payment_id");
        ApiException e = assertThrows(ApiException.class,
                () -> provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(f, NOTIFY, SECRET)));
        assertEquals("INVALID_PAYLOAD", e.code());
    }

    @Test
    void nonFinalResultIsAnswered409SoTheProviderRetriesLater() {
        ApiException e = assertThrows(ApiException.class,
                () -> provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(notification("2", "5450.00"), NOTIFY, SECRET)));
        assertEquals(HttpStatus.CONFLICT, e.status());
        assertEquals("PAYMENT_NOT_FINAL", e.code());
    }

    @Test
    void unparsableAmountBecomesZeroSoPaymentServiceFlagsAMismatch() {
        Map<String, String> f = notification("1", "abc");
        assertEquals(0L, provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(f, NOTIFY, SECRET)).amountMinor());
        Map<String, String> g = notification("1", "10.005");
        assertEquals(0L, provider("https://api.example.com").verifyAndParse(Map.of(), signedForm(g, NOTIFY, SECRET)).amountMinor());
    }

    // ---- initiate ----

    @Test
    void initiateSendsSignedRequestInKztAndReturnsHttpsRedirect() throws Exception {
        String api = fakeApi("<response><pg_status>ok</pg_status><pg_payment_id>fp-1</pg_payment_id>"
                + "<pg_redirect_url>https://pay.example/checkout/1</pg_redirect_url></response>");
        PaymentProvider.InitResult r = provider(api).initiate(payment(545000), order());
        assertEquals("fp-1", r.providerRef());
        assertEquals("https://pay.example/checkout/1", r.redirectUrl());
        assertEquals("/init_payment.php", lastPath.get());
        Map<String, String> sent = FreedomPayProvider.parseForm(lastBody.get().getBytes(StandardCharsets.UTF_8));
        assertEquals("m1", sent.get("pg_merchant_id"));
        assertEquals("5450.00", sent.get("pg_amount"));
        assertEquals("KZT", sent.get("pg_currency"));
        assertEquals("JEMIS order JM-100010", sent.get("pg_description"));
        assertTrue(sent.get("pg_order_id").startsWith("JM-100010-"));
        assertEquals("https://app.example/ok", sent.get("pg_success_url"));
        assertEquals("https://app.example/fail", sent.get("pg_failure_url"));
        String sig = sent.remove("pg_sig");
        assertTrue(FreedomPaySignature.matches("init_payment.php", sent, SECRET, sig));
    }

    @Test
    void initiateUsesAFreshOrderIdAndIdempotencyKeyForEveryAttempt() throws Exception {
        String api = fakeApi("<response><pg_status>ok</pg_status><pg_payment_id>fp-1</pg_payment_id>"
                + "<pg_redirect_url>https://pay.example/c</pg_redirect_url></response>");
        FreedomPayProvider p = provider(api);
        p.initiate(payment(1000), order());
        Map<String, String> first = FreedomPayProvider.parseForm(lastBody.get().getBytes(StandardCharsets.UTF_8));
        p.initiate(payment(1000), order());
        Map<String, String> second = FreedomPayProvider.parseForm(lastBody.get().getBytes(StandardCharsets.UTF_8));
        assertFalse(first.get("pg_order_id").equals(second.get("pg_order_id")));
        assertFalse(first.get("pg_idempotency_key").equals(second.get("pg_idempotency_key")));
    }

    @Test
    void initiateRejectedByProviderBecomes502() throws Exception {
        String api = fakeApi("<response><pg_status>error</pg_status><pg_error_description>bad merchant</pg_error_description></response>");
        ApiException e = assertThrows(ApiException.class, () -> provider(api).initiate(payment(1000), order()));
        assertEquals(HttpStatus.BAD_GATEWAY, e.status());
        assertEquals("PAYMENT_PROVIDER_ERROR", e.code());
    }

    @Test
    void initiateWithoutHttpsRedirectOrPaymentIdIsRefused() throws Exception {
        String httpRedirect = fakeApi("<response><pg_status>ok</pg_status><pg_payment_id>fp-1</pg_payment_id>"
                + "<pg_redirect_url>http://pay.example/c</pg_redirect_url></response>");
        assertEquals("PAYMENT_PROVIDER_ERROR", assertThrows(ApiException.class, () -> provider(httpRedirect).initiate(payment(1000), order())).code());
        server.stop(0);
        String noId = fakeApi("<response><pg_status>ok</pg_status><pg_redirect_url>https://pay.example/c</pg_redirect_url></response>");
        assertEquals("PAYMENT_PROVIDER_ERROR", assertThrows(ApiException.class, () -> provider(noId).initiate(payment(1000), order())).code());
        server.stop(0);
        String noUrl = fakeApi("<response><pg_status>ok</pg_status><pg_payment_id>fp-1</pg_payment_id></response>");
        assertEquals("PAYMENT_PROVIDER_ERROR", assertThrows(ApiException.class, () -> provider(noUrl).initiate(payment(1000), order())).code());
    }

    @Test
    void initiateWhenProviderIsUnreachableBecomes502() {
        ApiException e = assertThrows(ApiException.class, () -> provider("http://127.0.0.1:1").initiate(payment(1000), order()));
        assertEquals(HttpStatus.BAD_GATEWAY, e.status());
    }

    @Test
    void malformedXmlFromTheProviderBecomes502() throws Exception {
        String api = fakeApi("not xml at all");
        assertEquals(HttpStatus.BAD_GATEWAY, assertThrows(ApiException.class, () -> provider(api).initiate(payment(1000), order())).status());
    }

    // ---- refund ----

    @Test
    void refundCallsRevokeWithTheProviderReferenceAndAmount() throws Exception {
        String api = fakeApi("<response><pg_status>ok</pg_status></response>");
        provider(api).refund(payment(545000));
        assertEquals("/revoke.php", lastPath.get());
        Map<String, String> sent = FreedomPayProvider.parseForm(lastBody.get().getBytes(StandardCharsets.UTF_8));
        assertEquals("fp-777", sent.get("pg_payment_id"));
        assertEquals("5450.00", sent.get("pg_refund_amount"));
        String sig = sent.remove("pg_sig");
        assertTrue(FreedomPaySignature.matches("revoke.php", sent, SECRET, sig));
    }

    @Test
    void refundRefusedByProviderRaisesSoTheOrderIsNotMarkedRefunded() throws Exception {
        String api = fakeApi("<response><pg_status>error</pg_status><pg_error_description>receipt required</pg_error_description></response>");
        ApiException e = assertThrows(ApiException.class, () -> provider(api).refund(payment(1000)));
        assertEquals("REFUND_FAILED", e.code());
    }

    @Test
    void refundWhenProviderIsUnreachableBecomes502() {
        assertEquals(HttpStatus.BAD_GATEWAY,
                assertThrows(ApiException.class, () -> provider("http://127.0.0.1:1").refund(payment(1000))).status());
    }

    // ---- helpers ----

    @Test
    void toMajorKeepsTwoDecimals() {
        assertEquals("5450.00", FreedomPayProvider.toMajor(545000));
        assertEquals("0.05", FreedomPayProvider.toMajor(5));
        assertEquals("0.00", FreedomPayProvider.toMajor(0));
    }

    @Test
    void parseFormDecodesValuesAndToleratesEmptyBodyAndBareKeys() {
        assertTrue(FreedomPayProvider.parseForm(new byte[0]).isEmpty());
        Map<String, String> m = FreedomPayProvider.parseForm("a=b%20c&d=&e".getBytes(StandardCharsets.UTF_8));
        assertEquals("b c", m.get("a"));
        assertEquals("", m.get("d"));
        assertEquals("", m.get("e"));
    }
}
