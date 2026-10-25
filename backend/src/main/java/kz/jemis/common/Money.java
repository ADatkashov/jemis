package kz.jemis.common;

/** Integer money/quantity arithmetic. Prices are minor units per 1000 milli-units (1 unit). */
public final class Money {
    private Money() {}

    /** price per whole unit (minor) × quantity (milli), rounded half-up to minor units. */
    public static long lineTotal(long unitPriceMinor, long quantityMilli) {
        return Math.floorDiv(Math.multiplyExact(unitPriceMinor, quantityMilli) + 500, 1000L);
    }

    /** value × percent / 100, rounded half-up. */
    public static long percentOf(long valueMinor, long percent) {
        return Math.floorDiv(Math.multiplyExact(valueMinor, percent) + 50, 100L);
    }
}
