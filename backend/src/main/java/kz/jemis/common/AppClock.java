package kz.jemis.common;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AppClock {
    @Bean
    Clock clock() { return Clock.systemUTC(); }

    @Bean
    ZoneId businessZone(@Value("${jemis.timezone}") String tz) { return ZoneId.of(tz); }
}
