package kz.jemis.address;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Extension point for geocoding / map providers (e.g. 2GIS, Google Maps). No provider is bundled:
 * coordinates are optional and delivery-zone checks currently match by city only.
 */
public interface GeocodingProvider {
    record Coordinates(BigDecimal latitude, BigDecimal longitude) {}

    boolean isConfigured();

    Optional<Coordinates> geocode(String city, String street, String house);
}
