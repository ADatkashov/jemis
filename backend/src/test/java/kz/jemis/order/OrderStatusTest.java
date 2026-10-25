package kz.jemis.order;

import static kz.jemis.order.OrderStatus.*;
import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class OrderStatusTest {
    @Test
    void happyPathIsAllowedStepByStep() {
        OrderStatus[] path = {PENDING_PAYMENT, CONFIRMED, ACCEPTED, PREPARING, READY_FOR_DELIVERY, ASSIGNED_TO_COURIER,
                PICKED_UP, ON_THE_WAY, DELIVERED};
        for (int i = 0; i < path.length - 1; i++) {
            assertThat(path[i].canTransitionTo(path[i + 1])).as(path[i] + " -> " + path[i + 1]).isTrue();
        }
    }

    @Test
    void cannotSkipOrGoBackwards() {
        assertThat(PENDING_PAYMENT.canTransitionTo(DELIVERED)).isFalse();
        assertThat(CONFIRMED.canTransitionTo(PICKED_UP)).isFalse();
        assertThat(DELIVERED.canTransitionTo(ON_THE_WAY)).isFalse();
        assertThat(CANCELLED.canTransitionTo(CONFIRMED)).isFalse();
    }

    @Test
    void cannotCancelOnceHandedToCourier() {
        assertThat(ASSIGNED_TO_COURIER.canTransitionTo(CANCELLED)).isTrue();
        assertThat(PICKED_UP.canTransitionTo(CANCELLED)).isFalse();
        assertThat(ON_THE_WAY.canTransitionTo(CANCELLED)).isFalse();
        assertThat(DELIVERED.canTransitionTo(CANCELLED)).isFalse();
    }

    @Test
    void refundOnlyAfterDeliveryOrCancellation() {
        assertThat(DELIVERED.canTransitionTo(REFUNDED)).isTrue();
        assertThat(CANCELLED.canTransitionTo(REFUNDED)).isTrue();
        assertThat(PREPARING.canTransitionTo(REFUNDED)).isFalse();
        assertThat(REFUNDED.next()).isEmpty();
    }
}
