package kz.jemis.address;

import java.util.Optional;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnMissingBean(value = GeocodingProvider.class, ignored = NoopGeocodingProvider.class)
public class NoopGeocodingProvider implements GeocodingProvider {
    @Override public boolean isConfigured() { return false; }
    @Override public Optional<Coordinates> geocode(String city, String street, String house) { return Optional.empty(); }
}
