package kz.jemis.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import kz.jemis.common.ApiException;
import kz.jemis.order.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * DEVELOPMENT-ONLY provider. It moves no money. Disabled unless {@code jemis.payment.mock.enabled=true}.
 * Notifications are authenticated with HMAC-SHA256(secret, body) in the {@code X-Jemis-Signature} header,
 * exactly like a real provider integration would be verified.
 */
@Component
public class MockPaymentProvider implements PaymentProvider {
    public static final String SIGNATURE_HEADER = "x-jemis-signature";
    private final boolean enabled;
    private final byte[] secret;
    private final ObjectMapper mapper;

    public MockPaymentProvider(@Value("${jemis.payment.mock.enabled:false}") boolean enabled,
                               @Value("${jemis.payment.mock.secret:}") String secret, ObjectMapper mapper) {
        if (enabled && secret.length() < 16) {
            throw new IllegalStateException("jemis.payment.mock.secret must be set (>=16 chars) when the mock provider is enabled");
        }
        this.enabled = enabled;
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.mapper = mapper;
    }

    @Override public String key() { return "mock"; }
    @Override public boolean isEnabled() { return enabled; }
    @Override public boolean developmentOnly() { return true; }

    @Override
    public InitResult initiate(Payment payment, Order order) {
        return new InitResult("mock_" + UUID.randomUUID(), null,
                "DEVELOPMENT ONLY mock payment: no real transaction. Use POST /api/v1/dev/payments/{id}/simulate");
    }

    @Override
    public Event verifyAndParse(Map<String, String> headers, byte[] body) {
        if (!enabled) throw ApiException.unauthorized("INVALID_SIGNATURE", "Invalid signature");
        String sig = headers.get(SIGNATURE_HEADER);
        if (sig == null || !MessageDigest.isEqual(sign(body).getBytes(StandardCharsets.UTF_8), sig.getBytes(StandardCharsets.UTF_8))) {
            throw ApiException.unauthorized("INVALID_SIGNATURE", "Invalid signature");
        }
        try {
            JsonNode n = mapper.readTree(body);
            return new Event(n.path("eventId").asText(), n.path("providerRef").asText(),
                    EventType.valueOf(n.path("type").asText()), n.path("amountMinor").asLong(), n.path("failureReason").asText(null));
        } catch (Exception e) {
            throw ApiException.badRequest("INVALID_PAYLOAD", "Malformed notification");
        }
    }

    @Override public void refund(Payment payment) { /* mock: nothing to call */ }

    public String sign(byte[] body) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(body));
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new IllegalStateException(e);
        }
    }
}
