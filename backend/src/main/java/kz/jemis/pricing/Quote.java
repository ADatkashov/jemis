package kz.jemis.pricing;

import java.util.List;
import java.util.UUID;
import kz.jemis.catalog.Unit;

public record Quote(List<Line> lines, long subtotalMinor, long discountMinor, String promoCode, String promoError,
                    long deliveryFeeMinor, long serviceFeeMinor, long totalMinor, long minOrderMinor,
                    Long freeDeliveryThresholdMinor, boolean deliveryEstimated, List<String> issues, String currency) {

    public record Line(UUID productId, String sku, String name, String imageUrl, Unit unit, boolean weighted,
                       int stepMilli, long unitPriceMinor, Long oldPriceMinor, long quantityMilli, long lineTotalMinor,
                       boolean available, long availableMilli, String issue) {}

    public boolean checkoutBlocked() { return !issues.isEmpty(); }
}
