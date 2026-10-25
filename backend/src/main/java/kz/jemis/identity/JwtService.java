package kz.jemis.identity;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SecretKey key;
    private final SecurityProperties props;

    public JwtService(SecurityProperties props) {
        byte[] secret = props.jwtSecret() == null ? new byte[0] : props.jwtSecret().getBytes(StandardCharsets.UTF_8);
        if (secret.length < 32) {
            throw new IllegalStateException(
                    "JEMIS_JWT_SECRET must be set and at least 32 bytes long (see .env.example)");
        }
        this.key = Keys.hmacShaKeyFor(secret);
        this.props = props;
    }

    public String createAccessToken(User u) {
        Instant now = Instant.now();
        return Jwts.builder().subject(u.getId().toString()).claim("role", u.getRole().name())
                .issuedAt(Date.from(now)).expiration(Date.from(now.plusSeconds(props.accessTtlMinutes() * 60L)))
                .signWith(key).compact();
    }

    public long accessTtlSeconds() { return props.accessTtlMinutes() * 60L; }

    public Optional<AuthUser> parse(String token) {
        try {
            Claims c = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
            return Optional.of(new AuthUser(UUID.fromString(c.getSubject()), Role.valueOf(c.get("role", String.class))));
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
