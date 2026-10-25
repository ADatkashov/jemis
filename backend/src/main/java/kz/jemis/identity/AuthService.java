package kz.jemis.identity;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import kz.jemis.common.ApiException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    public record Tokens(String accessToken, String refreshToken, long expiresInSeconds) {}

    private static final SecureRandom RANDOM = new SecureRandom();
    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordResetTokenRepository resetTokens;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final SecurityProperties props;
    private final ResetTokenSender resetSender;
    private final String dummyHash;

    public AuthService(UserRepository users, RefreshTokenRepository refreshTokens,
                       PasswordResetTokenRepository resetTokens, PasswordEncoder encoder, JwtService jwt,
                       SecurityProperties props, ResetTokenSender resetSender) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.resetTokens = resetTokens;
        this.encoder = encoder;
        this.jwt = jwt;
        this.props = props;
        this.resetSender = resetSender;
        this.dummyHash = encoder.encode("jemis-dummy-password");
    }

    @Transactional
    public User register(String email, String phone, String password, String fullName, String locale) {
        String e = normalizeEmail(email);
        String p = normalizePhone(phone);
        if (e == null && p == null) throw ApiException.badRequest("CONTACT_REQUIRED", "Email or phone is required");
        if ((e != null && users.findByEmail(e).isPresent()) || (p != null && users.findByPhone(p).isPresent())) {
            throw ApiException.conflict("ACCOUNT_EXISTS", "An account with these contact details already exists");
        }
        User u = new User();
        u.setEmail(e);
        u.setPhone(p);
        u.setFullName(fullName.trim());
        u.setPasswordHash(encoder.encode(password));
        u.setRole(Role.CUSTOMER);
        u.setLocale(locale == null ? "ru" : locale);
        return users.save(u);
    }

    @Transactional
    public Tokens login(String identifier, String password) {
        Optional<User> found = findByIdentifier(identifier);
        // Always run a bcrypt comparison so response time does not reveal whether the account exists.
        boolean ok = encoder.matches(password, found.map(User::getPasswordHash).orElse(dummyHash));
        if (found.isEmpty() || !ok || !found.get().isActive()) {
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Invalid credentials");
        }
        return issue(found.get());
    }

    @Transactional(noRollbackFor = ApiException.class)
    public Tokens refresh(String refreshToken) {
        RefreshToken t = refreshTokens.findByTokenHash(hash(refreshToken))
                .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Invalid refresh token"));
        Instant now = Instant.now();
        if (t.getRevokedAt() != null) {
            // Reuse of a rotated token: treat as theft and drop every session of this user.
            revokeAll(t.getUserId());
            throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Invalid refresh token");
        }
        if (t.getExpiresAt().isBefore(now)) throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Invalid refresh token");
        User u = users.findById(t.getUserId()).filter(User::isActive)
                .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Invalid refresh token"));
        t.setRevokedAt(now);
        return issue(u);
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokens.findByTokenHash(hash(refreshToken)).ifPresent(t -> {
            if (t.getRevokedAt() == null) t.setRevokedAt(Instant.now());
        });
    }

    @Transactional
    public void requestPasswordReset(String identifier) {
        findByIdentifier(identifier).filter(User::isActive).ifPresent(u -> {
            String raw = randomToken();
            PasswordResetToken t = new PasswordResetToken();
            t.setUserId(u.getId());
            t.setTokenHash(hash(raw));
            t.setExpiresAt(Instant.now().plus(30, ChronoUnit.MINUTES));
            resetTokens.save(t);
            resetSender.send(u, raw);
        });
    }

    @Transactional
    public void confirmPasswordReset(String token, String newPassword) {
        PasswordResetToken t = resetTokens.findByTokenHash(hash(token))
                .filter(x -> x.getUsedAt() == null && x.getExpiresAt().isAfter(Instant.now()))
                .orElseThrow(() -> ApiException.badRequest("INVALID_RESET_TOKEN", "Invalid or expired token"));
        User u = users.findById(t.getUserId()).orElseThrow();
        u.setPasswordHash(encoder.encode(newPassword));
        t.setUsedAt(Instant.now());
        revokeAll(u.getId());
    }

    @Transactional
    public void changePassword(UUID userId, String current, String next) {
        User u = users.findById(userId).orElseThrow();
        if (!encoder.matches(current, u.getPasswordHash())) {
            throw ApiException.badRequest("INVALID_CURRENT_PASSWORD", "Current password is incorrect");
        }
        u.setPasswordHash(encoder.encode(next));
        revokeAll(userId);
    }

    @Transactional
    public void revokeAll(UUID userId) {
        refreshTokens.revokeAllForUser(userId, Instant.now());
    }

    public Tokens issue(User u) {
        String raw = randomToken();
        RefreshToken t = new RefreshToken();
        t.setUserId(u.getId());
        t.setTokenHash(hash(raw));
        t.setExpiresAt(Instant.now().plus(props.refreshTtlDays(), ChronoUnit.DAYS));
        refreshTokens.save(t);
        return new Tokens(jwt.createAccessToken(u), raw, jwt.accessTtlSeconds());
    }

    private Optional<User> findByIdentifier(String identifier) {
        if (identifier == null) return Optional.empty();
        String id = identifier.trim();
        return id.contains("@") ? users.findByEmail(id) : Optional.ofNullable(normalizePhone(id)).flatMap(users::findByPhone);
    }

    public static String normalizeEmail(String email) {
        return email == null || email.isBlank() ? null : email.trim().toLowerCase();
    }

    public static String normalizePhone(String phone) {
        if (phone == null || phone.isBlank()) return null;
        String digits = phone.replaceAll("[\\s\\-()]", "");
        if (digits.startsWith("8") && digits.length() == 11) digits = "+7" + digits.substring(1);
        if (!digits.startsWith("+")) digits = "+" + digits;
        return digits;
    }

    private static String randomToken() {
        byte[] b = new byte[32];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    static String hash(String raw) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
