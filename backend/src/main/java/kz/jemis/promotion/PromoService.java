package kz.jemis.promotion;

import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.Money;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PromoService {
    /** A cart line as seen by promotion rules. */
    public record Line(UUID productId, UUID categoryId, boolean alreadyDiscounted, long totalMinor) {}
    public record Result(Promotion promo, long discountMinor) {}

    private final PromotionRepository promos;
    private final EntityManager em;

    public PromoService(PromotionRepository promos, EntityManager em) {
        this.promos = promos;
        this.em = em;
    }

    // A rejected promo is a normal business outcome: it must not mark the caller's transaction rollback-only.
    @Transactional(readOnly = true, noRollbackFor = ApiException.class)
    public Result evaluate(String code, UUID userId, List<Line> lines, long subtotalMinor, Instant now) {
        Promotion p = promos.findByCodeIgnoreCase(code.trim())
                .filter(Promotion::isActive)
                .orElseThrow(() -> ApiException.badRequest("PROMO_NOT_FOUND", "Promo code not found"));
        if (p.getStartsAt() != null && now.isBefore(p.getStartsAt())) throw ApiException.badRequest("PROMO_NOT_STARTED", "Promo code is not active yet");
        if (p.getEndsAt() != null && !now.isBefore(p.getEndsAt())) throw ApiException.badRequest("PROMO_EXPIRED", "Promo code has expired");
        if (p.getUsageLimit() != null && p.getUsedCount() >= p.getUsageLimit()) throw ApiException.badRequest("PROMO_USAGE_LIMIT", "Promo code usage limit reached");
        if (p.getPerCustomerLimit() != null && userId != null) {
            long used = ((Number) em.createNativeQuery("select count(*) from promo_redemptions where promo_id = :p and user_id = :u")
                    .setParameter("p", p.getId()).setParameter("u", userId).getSingleResult()).longValue();
            if (used >= p.getPerCustomerLimit()) throw ApiException.badRequest("PROMO_CUSTOMER_LIMIT", "You have already used this promo code");
        }
        if (subtotalMinor < p.getMinOrderMinor()) {
            throw new ApiException(org.springframework.http.HttpStatus.BAD_REQUEST, "PROMO_MIN_ORDER",
                    "Order total is below the promo minimum", java.util.Map.of("minOrderMinor", p.getMinOrderMinor()));
        }
        long discount = discountFor(p, lines);
        if (discount <= 0) throw ApiException.badRequest("PROMO_NOT_APPLICABLE", "Promo code does not apply to these items");
        return new Result(p, discount);
    }

    /**
     * Pure calculation: eligible = lines in the promo category (if any); already-discounted items are
     * excluded unless the promotion is explicitly stackable. Result is capped by max discount and eligible total.
     */
    public static long discountFor(Promotion p, List<Line> lines) {
        long eligible = lines.stream()
                .filter(l -> p.getCategoryId() == null || p.getCategoryId().equals(l.categoryId()))
                .filter(l -> p.isStackable() || !l.alreadyDiscounted())
                .mapToLong(Line::totalMinor).sum();
        long d = p.getType() == Promotion.Type.PERCENT ? Money.percentOf(eligible, p.getValue()) : p.getValue();
        if (p.getMaxDiscountMinor() != null) d = Math.min(d, p.getMaxDiscountMinor());
        return Math.min(d, eligible);
    }

    /** Atomically takes one use of the promotion; fails if the global limit was exhausted concurrently. */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public void redeem(Promotion p, UUID userId, UUID orderId) {
        if (promos.tryConsume(p.getId()) == 0) throw ApiException.badRequest("PROMO_USAGE_LIMIT", "Promo code usage limit reached");
        em.createNativeQuery("insert into promo_redemptions(promo_id, user_id, order_id) values (:p,:u,:o)")
                .setParameter("p", p.getId()).setParameter("u", userId).setParameter("o", orderId).executeUpdate();
    }

    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public void releaseForOrder(UUID orderId) {
        List<?> r = em.createNativeQuery("delete from promo_redemptions where order_id = :o returning promo_id")
                .setParameter("o", orderId).getResultList();
        for (Object promoId : r) promos.release((UUID) promoId);
    }
}
