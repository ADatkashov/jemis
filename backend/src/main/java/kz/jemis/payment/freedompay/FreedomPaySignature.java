package kz.jemis.payment.freedompay;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/**
 * Freedom Pay's {@code pg_sig}: MD5 hex of {@code scriptName;value1;value2;...;secretKey}, where the values are every
 * {@code pg_*} field except {@code pg_sig}, ordered by field name. MD5 is the provider's own algorithm; a stronger hash
 * would simply not match what Freedom Pay computes. Pure function so it can be unit-tested without I/O.
 */
final class FreedomPaySignature {

    private FreedomPaySignature() {
    }

    /** @param fields every {@code pg_*} field except {@code pg_sig} (the caller removes it). */
    static String compute(String scriptName, Map<String, String> fields, String secretKey) {
        StringBuilder toSign = new StringBuilder(scriptName);
        for (String value : new TreeMap<>(fields).values()) {
            toSign.append(';').append(value == null ? "" : value);
        }
        toSign.append(';').append(secretKey);
        return md5Hex(toSign.toString());
    }

    static boolean matches(String scriptName, Map<String, String> fields, String secretKey, String expectedSig) {
        if (expectedSig == null) return false;
        byte[] computed = compute(scriptName, fields, secretKey).getBytes(StandardCharsets.UTF_8);
        byte[] expected = expectedSig.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.UTF_8);
        return MessageDigest.isEqual(computed, expected);
    }

    private static String md5Hex(String input) {
        try {
            byte[] hash = MessageDigest.getInstance("MD5").digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16)).append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("MD5 not available", e); // every JVM ships MD5
        }
    }
}
