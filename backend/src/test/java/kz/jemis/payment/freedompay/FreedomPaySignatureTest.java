package kz.jemis.payment.freedompay;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** No official worked example was available, so these pin the documented shape: scriptName;values-by-key;secret, MD5 hex. */
class FreedomPaySignatureTest {

    @Test
    void sortsFieldsByKeyNotInsertionOrder() {
        Map<String, String> a = new LinkedHashMap<>();
        a.put("pg_amount", "10.00");
        a.put("pg_merchant_id", "m1");
        Map<String, String> b = new LinkedHashMap<>();
        b.put("pg_merchant_id", "m1");
        b.put("pg_amount", "10.00");
        assertEquals(FreedomPaySignature.compute("init_payment.php", a, "secret"),
                FreedomPaySignature.compute("init_payment.php", b, "secret"));
    }

    @Test
    void matchesItsOwnHandExpansion() throws Exception {
        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("pg_amount", "10.00");
        fields.put("pg_merchant_id", "m1");
        String expected = HexOf("init_payment.php;10.00;m1;secret");
        assertEquals(expected, FreedomPaySignature.compute("init_payment.php", fields, "secret"));
    }

    @Test
    void nullValueIsSignedAsEmpty() throws Exception {
        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("pg_a", null);
        fields.put("pg_b", "x");
        assertEquals(HexOf("s.php;;x;k"), FreedomPaySignature.compute("s.php", fields, "k"));
    }

    @Test
    void matchesAcceptsOnlyTheRightSignatureCaseInsensitively() {
        Map<String, String> fields = Map.of("pg_payment_id", "123", "pg_result", "1");
        String sig = FreedomPaySignature.compute("result.php", fields, "s3cret");
        assertTrue(FreedomPaySignature.matches("result.php", fields, "s3cret", sig));
        assertTrue(FreedomPaySignature.matches("result.php", fields, "s3cret", sig.toUpperCase()));
        assertFalse(FreedomPaySignature.matches("result.php", fields, "other", sig));
        assertFalse(FreedomPaySignature.matches("other.php", fields, "s3cret", sig));
        assertFalse(FreedomPaySignature.matches("result.php", fields, "s3cret", null));
    }

    private static String HexOf(String input) throws Exception {
        byte[] hash = MessageDigest.getInstance("MD5").digest(input.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte x : hash) sb.append(String.format("%02x", x));
        return sb.toString();
    }
}
