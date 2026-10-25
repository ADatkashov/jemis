package kz.jemis.identity;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "jemis.security")
public record SecurityProperties(String jwtSecret, int accessTtlMinutes, int refreshTtlDays,
                                 String corsAllowedOrigins, int authRequestsPerMinute) {}
