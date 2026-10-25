package kz.jemis.identity;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
public class ResetTokenSenders {
    private static final Logger log = LoggerFactory.getLogger(ResetTokenSenders.class);

    /** Production default: no email/SMS provider is configured, so nothing can be delivered. */
    @Bean
    @Profile("!dev & !test")
    ResetTokenSender notConfiguredSender() {
        return (user, token) -> log.warn("Password reset requested for user {} but no email/SMS provider is configured",
                user.getId());
    }

    /** DEVELOPMENT ONLY: prints the token so the flow can be exercised locally. */
    @Bean
    @Profile("dev")
    ResetTokenSender devLoggingSender() {
        return (user, token) -> log.warn("[DEV ONLY] password reset token for user {}: {}", user.getId(), token);
    }
}
