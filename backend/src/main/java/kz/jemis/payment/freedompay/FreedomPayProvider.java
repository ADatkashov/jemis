package kz.jemis.payment.freedompay;

import java.math.BigDecimal;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.order.Order;
import kz.jemis.payment.Payment;
import kz.jemis.payment.PaymentProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

/**
 * Freedom Pay (classic {@code pg_*} form-POST / XML API, hosted checkout), ported from the adatkashov/zairo
 * integration. Card data is entered on Freedom Pay's page and never reaches this server. Disabled unless
 * {@code jemis.payment.freedompay.enabled=true}; when enabled the configuration is validated at startup.
 *
 * <p>The redirect back to {@code success-url} is only UX: an order is confirmed solely by the signed Result-notify
 * webhook ({@link #verifyAndParse}). Amounts are stored in minor units (tiyn) and sent to Freedom Pay in KZT.
 *
 * <p><b>Not confirmed against a real merchant account</b> (same open points as in zairo's ADR-0006); check them in
 * Freedom Pay's sandbox/merchant panel before real money flows:
 * <ul>
 *   <li>the script name Freedom Pay signs Result-notify callbacks with ({@code result-notify-script-name}, default
 *   {@code result.php}) is whatever the merchant panel is configured to call;</li>
 *   <li>the field carrying a failure reason ({@code pg_failure_description}) and the exact retry/idempotency
 *   behaviour of {@code pg_idempotency_key};</li>
 *   <li>refunds ({@code revoke.php}) send no fiscal receipt positions; if Freedom Pay requires them the refund fails
 *   honestly and the order stays unrefunded;</li>
 *   <li>whether the unsigned {@code <pg_status>ok</pg_status>} acknowledgement is enough to stop retries.</li>
 * </ul>
 */
@Component
public class FreedomPayProvider implements PaymentProvider {
    public static final String KEY = "freedompay";

    private static final Logger log = LoggerFactory.getLogger(FreedomPayProvider.class);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final boolean enabled;
    private final String merchantId;
    private final String secretKey;
    private final String resultNotifyScriptName;
    private final String successUrl;
    private final String failureUrl;
    private final FreedomPayHttpClient http;

    public FreedomPayProvider(@Value("${jemis.payment.freedompay.enabled:false}") boolean enabled,
                              @Value("${jemis.payment.freedompay.api-url:}") String apiUrl,
                              @Value("${jemis.payment.freedompay.merchant-id:}") String merchantId,
                              @Value("${jemis.payment.freedompay.secret-key:}") String secretKey,
                              @Value("${jemis.payment.freedompay.result-notify-script-name:result.php}") String resultNotifyScriptName,
                              @Value("${jemis.payment.freedompay.success-url:}") String successUrl,
                              @Value("${jemis.payment.freedompay.failure-url:}") String failureUrl) {
        this.enabled = enabled;
        this.merchantId = merchantId;
        this.secretKey = secretKey;
        this.resultNotifyScriptName = resultNotifyScriptName;
        this.successUrl = successUrl;
        this.failureUrl = failureUrl;
        if (enabled) {
            require(apiUrl, "api-url", "JEMIS_FREEDOMPAY_API_URL");
            require(merchantId, "merchant-id", "JEMIS_FREEDOMPAY_MERCHANT_ID");
            require(secretKey, "secret-key", "JEMIS_FREEDOMPAY_SECRET_KEY");
            require(resultNotifyScriptName, "result-notify-script-name", "JEMIS_FREEDOMPAY_RESULT_NOTIFY_SCRIPT");
            require(successUrl, "success-url", "JEMIS_PAYMENT_SUCCESS_URL");
            require(failureUrl, "failure-url", "JEMIS_PAYMENT_FAILURE_URL");
            if (!apiUrl.startsWith("https://") && !isLoopback(apiUrl)) {
                throw new IllegalStateException("jemis.payment.freedompay.api-url must be https");
            }
            this.http = new FreedomPayHttpClient(apiUrl.replaceAll("/+$", ""));
        } else {
            this.http = null;
        }
    }

    @Override public String key() { return KEY; }
    @Override public boolean isEnabled() { return enabled; }
    @Override public boolean developmentOnly() { return false; }

    @Override
    public InitResult initiate(Payment payment, Order order) {
        Map<String, String> fields = new HashMap<>();
        fields.put("pg_merchant_id", merchantId);
        fields.put("pg_amount", toMajor(payment.getAmountMinor()));
        fields.put("pg_currency", payment.getCurrency());
        fields.put("pg_description", "JEMIS order " + order.getNumber());
        // Free-form on Freedom Pay's side: the webhook is matched by pg_payment_id (our provider_ref), so a retry after a
        // failed attempt gets a fresh pg_order_id instead of colliding with the previous one.
        fields.put("pg_order_id", order.getNumber() + "-" + UUID.randomUUID().toString().substring(0, 8));
        fields.put("pg_success_url", successUrl);
        fields.put("pg_failure_url", failureUrl);
        fields.put("pg_idempotency_key", UUID.randomUUID().toString());
        fields.put("pg_salt", salt());
        sign("init_payment.php", fields);

        Map<String, String> response = call("init_payment.php", fields);
        if (!"ok".equalsIgnoreCase(response.get("pg_status"))) {
            log.warn("Freedom Pay refused to create a payment for order {}: {}", order.getNumber(), errorMessage(response));
            throw new ApiException(HttpStatus.BAD_GATEWAY, "PAYMENT_PROVIDER_ERROR",
                    "Online payment is temporarily unavailable", null);
        }
        String providerRef = response.get("pg_payment_id");
        String redirectUrl = response.get("pg_redirect_url");
        if (providerRef == null || providerRef.isBlank() || redirectUrl == null || !redirectUrl.startsWith("https://")) {
            log.error("Freedom Pay returned no usable payment id / https redirect URL for order {}", order.getNumber());
            throw new ApiException(HttpStatus.BAD_GATEWAY, "PAYMENT_PROVIDER_ERROR",
                    "Online payment is temporarily unavailable", null);
        }
        return new InitResult(providerRef, redirectUrl, null);
    }

    /**
     * Verifies a Result-notify delivery (form-urlencoded {@code pg_*} fields signed with {@code pg_sig}).
     * {@code pg_result}: 1 = paid, 0 = failed; anything else (e.g. 2 = incomplete) is not final, so it is rejected with
     * 409 and Freedom Pay retries later instead of the payment being closed too early.
     */
    @Override
    public Event verifyAndParse(Map<String, String> headers, byte[] body) {
        if (!enabled) throw ApiException.unauthorized("INVALID_SIGNATURE", "Invalid signature");
        Map<String, String> fields = parseForm(body);
        String sig = fields.remove("pg_sig");
        if (!FreedomPaySignature.matches(resultNotifyScriptName, fields, secretKey, sig)) {
            throw ApiException.unauthorized("INVALID_SIGNATURE", "Invalid signature");
        }
        String paymentId = fields.get("pg_payment_id");
        if (paymentId == null || paymentId.isBlank()) throw ApiException.badRequest("INVALID_PAYLOAD", "Malformed notification");
        String result = fields.getOrDefault("pg_result", "");
        EventType type;
        switch (result) {
            case "1" -> type = EventType.SUCCEEDED;
            case "0" -> type = EventType.FAILED;
            default -> throw ApiException.conflict("PAYMENT_NOT_FINAL", "Payment has no final result yet");
        }
        long amountMinor = 0;
        try {
            amountMinor = new BigDecimal(fields.getOrDefault("pg_amount", "")).movePointRight(2).longValueExact();
        } catch (NumberFormatException | ArithmeticException e) {
            // stays 0: PaymentService treats a SUCCEEDED event whose amount differs from the order as a mismatch
        }
        String reason = type == EventType.FAILED ? firstNonBlank(fields.get("pg_failure_description"), fields.get("pg_error_description")) : null;
        // No per-delivery event id exists: pg_payment_id (+ result) is the dedup key; retries reuse it.
        return new Event(paymentId + ":" + result, paymentId, type, amountMinor, reason);
    }

    @Override
    public void refund(Payment payment) {
        Map<String, String> fields = new HashMap<>();
        fields.put("pg_merchant_id", merchantId);
        fields.put("pg_payment_id", payment.getProviderRef());
        fields.put("pg_refund_amount", toMajor(payment.getAmountMinor()));
        fields.put("pg_salt", salt());
        sign("revoke.php", fields);
        Map<String, String> response = call("revoke.php", fields);
        if (!"ok".equalsIgnoreCase(response.get("pg_status"))) {
            log.warn("Freedom Pay refund of payment {} failed: {}", payment.getId(), errorMessage(response));
            throw ApiException.conflict("REFUND_FAILED", "The payment provider did not accept the refund");
        }
    }

    private Map<String, String> call(String script, Map<String, String> fields) {
        try {
            return http.post(script, fields);
        } catch (FreedomPayHttpException e) {
            log.warn("Freedom Pay {} failed: {}", script, e.getMessage());
            throw new ApiException(HttpStatus.BAD_GATEWAY, "PAYMENT_PROVIDER_ERROR",
                    "Online payment is temporarily unavailable", null);
        }
    }

    private void sign(String script, Map<String, String> fields) {
        fields.put("pg_sig", FreedomPaySignature.compute(script, fields, secretKey));
    }

    /** Minor units (tiyn) to KZT with two decimals, e.g. 545000 -> "5450.00". */
    static String toMajor(long minor) {
        return BigDecimal.valueOf(minor, 2).toPlainString();
    }

    static Map<String, String> parseForm(byte[] body) {
        Map<String, String> out = new LinkedHashMap<>();
        String text = new String(body, StandardCharsets.UTF_8);
        if (text.isBlank()) return out;
        for (String pair : text.split("&")) {
            int i = pair.indexOf('=');
            String k = URLDecoder.decode(i < 0 ? pair : pair.substring(0, i), StandardCharsets.UTF_8);
            String v = i < 0 ? "" : URLDecoder.decode(pair.substring(i + 1), StandardCharsets.UTF_8);
            out.put(k, v);
        }
        return out;
    }

    private static String errorMessage(Map<String, String> response) {
        String d = response.get("pg_error_description");
        return d != null && !d.isBlank() ? d : "pg_status=" + response.get("pg_status");
    }

    private static String firstNonBlank(String a, String b) {
        return a != null && !a.isBlank() ? a : (b != null && !b.isBlank() ? b : null);
    }

    private static String salt() {
        return Long.toUnsignedString(RANDOM.nextLong());
    }

    private static void require(String value, String property, String env) {
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("jemis.payment.freedompay.enabled=true but jemis.payment.freedompay." + property
                    + " is not set (" + env + ")");
        }
    }

    private static boolean isLoopback(String url) {
        try {
            String host = URI.create(url).getHost();
            return host != null && (host.equals("localhost") || host.equals("127.0.0.1")) && url.toLowerCase(Locale.ROOT).startsWith("http://");
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
