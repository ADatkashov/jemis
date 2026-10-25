package kz.jemis.integration;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import kz.jemis.identity.ResetTokenSender;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;

@TestConfiguration
class TestBeans {
    static final Map<UUID, String> RESET_TOKENS = new ConcurrentHashMap<>();

    @Bean
    ResetTokenSender capturingSender() { return (u, t) -> RESET_TOKENS.put(u.getId(), t); }
}
