package kz.jemis.order;

import java.util.EnumSet;
import java.util.Set;

/** Fulfilment lifecycle. Payment state is tracked separately in {@link kz.jemis.payment.PaymentStatus}. */
public enum OrderStatus {
    PENDING_PAYMENT, CONFIRMED, ACCEPTED, PREPARING, READY_FOR_DELIVERY, ASSIGNED_TO_COURIER, PICKED_UP, ON_THE_WAY,
    DELIVERED, CANCELLED, REFUNDED;

    public Set<OrderStatus> next() {
        return switch (this) {
            case PENDING_PAYMENT -> EnumSet.of(CONFIRMED, CANCELLED);
            case CONFIRMED -> EnumSet.of(ACCEPTED, CANCELLED);
            case ACCEPTED -> EnumSet.of(PREPARING, CANCELLED);
            case PREPARING -> EnumSet.of(READY_FOR_DELIVERY, CANCELLED);
            case READY_FOR_DELIVERY -> EnumSet.of(ASSIGNED_TO_COURIER, CANCELLED);
            case ASSIGNED_TO_COURIER -> EnumSet.of(PICKED_UP, READY_FOR_DELIVERY, CANCELLED);
            case PICKED_UP -> EnumSet.of(ON_THE_WAY);
            case ON_THE_WAY -> EnumSet.of(DELIVERED);
            case DELIVERED, CANCELLED -> EnumSet.of(REFUNDED);
            case REFUNDED -> EnumSet.noneOf(OrderStatus.class);
        };
    }

    public boolean canTransitionTo(OrderStatus to) { return next().contains(to); }

    public boolean isTerminal() { return this == REFUNDED || this == CANCELLED || this == DELIVERED; }
}
