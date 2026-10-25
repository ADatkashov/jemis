package kz.jemis.promotion;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;
import kz.jemis.promotion.PromoService.Line;
import org.junit.jupiter.api.Test;

class PromoCalcTest {
    private static final UUID FRUIT = UUID.randomUUID();
    private static final UUID MILK = UUID.randomUUID();

    private static Promotion promo(Promotion.Type t, long value) {
        Promotion p = new Promotion();
        p.setType(t);
        p.setValue(value);
        return p;
    }

    private final List<Line> lines = List.of(
            new Line(UUID.randomUUID(), FRUIT, false, 100_000),
            new Line(UUID.randomUUID(), FRUIT, true, 50_000),   // already discounted
            new Line(UUID.randomUUID(), MILK, false, 30_000));

    @Test
    void percentAppliesOnlyToNonDiscountedItemsByDefault() {
        // eligible = 100_000 + 30_000 = 130_000; 10% = 13_000
        assertThat(PromoService.discountFor(promo(Promotion.Type.PERCENT, 10), lines)).isEqualTo(13_000);
    }

    @Test
    void stackablePromoAlsoCoversDiscountedItems() {
        Promotion p = promo(Promotion.Type.PERCENT, 10);
        p.setStackable(true);
        assertThat(PromoService.discountFor(p, lines)).isEqualTo(18_000);
    }

    @Test
    void categoryRestrictionLimitsEligibleItems() {
        Promotion p = promo(Promotion.Type.PERCENT, 50);
        p.setCategoryId(MILK);
        assertThat(PromoService.discountFor(p, lines)).isEqualTo(15_000);
    }

    @Test
    void maxDiscountCapsPercentPromos() {
        Promotion p = promo(Promotion.Type.PERCENT, 50);
        p.setMaxDiscountMinor(5_000L);
        assertThat(PromoService.discountFor(p, lines)).isEqualTo(5_000);
    }

    @Test
    void fixedDiscountNeverExceedsEligibleTotal() {
        Promotion p = promo(Promotion.Type.FIXED, 1_000_000);
        assertThat(PromoService.discountFor(p, lines)).isEqualTo(130_000);
    }

    @Test
    void noEligibleItemsMeansNoDiscount() {
        Promotion p = promo(Promotion.Type.PERCENT, 10);
        p.setCategoryId(UUID.randomUUID());
        assertThat(PromoService.discountFor(p, lines)).isZero();
    }
}
