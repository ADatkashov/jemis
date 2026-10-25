package kz.jemis.courier;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.identity.AuthUser;
import kz.jemis.order.Order;
import kz.jemis.order.OrderDto;
import kz.jemis.order.OrderEvent;
import kz.jemis.order.OrderEventRepository;
import kz.jemis.order.OrderRepository;
import kz.jemis.order.OrderStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders")
public class TrackingController {
    public record LastLocation(BigDecimal latitude, BigDecimal longitude, Instant at) {}
    public record CourierView(String name, String photoUrl, String maskedPhone, LastLocation lastKnownLocation) {}
    /**
     * Honest tracking: {@code liveTracking} is always false because no real-time GPS stream is wired up;
     * {@code lastKnownLocation} is the courier's last reported point (only with their consent) and {@code eta} is
     * never fabricated - only the customer's chosen delivery window is returned.
     */
    public record Tracking(UUID orderId, String number, OrderStatus status, OrderDto.SlotSnapshot scheduledWindow,
                           boolean liveTracking, Instant eta, CourierView courier, List<OrderDto.EventDto> timeline) {}

    private final OrderRepository orders;
    private final OrderEventRepository events;
    private final CourierRepository couriers;

    public TrackingController(OrderRepository orders, OrderEventRepository events, CourierRepository couriers) {
        this.orders = orders;
        this.events = events;
        this.couriers = couriers;
    }

    @GetMapping("/{id}/tracking")
    @Transactional(readOnly = true)
    public Tracking tracking(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        Order o = orders.findByIdAndUserId(id, me.id()).orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        CourierView cv = null;
        boolean active = o.getStatus() == OrderStatus.ASSIGNED_TO_COURIER || o.getStatus() == OrderStatus.PICKED_UP
                || o.getStatus() == OrderStatus.ON_THE_WAY;
        if (o.getCourierId() != null && active) {
            Courier c = couriers.findById(o.getCourierId()).orElse(null);
            if (c != null) {
                LastLocation loc = c.isTrackingConsent() && c.getLastLocationAt() != null
                        ? new LastLocation(c.getLastLat(), c.getLastLng(), c.getLastLocationAt()) : null;
                cv = new CourierView(c.getDisplayName(), c.getPhotoUrl(), mask(c.getPhone()), loc);
            }
        }
        List<OrderDto.EventDto> tl = events.findByOrderIdOrderByCreatedAt(o.getId()).stream()
                .map((OrderEvent e) -> new OrderDto.EventDto(e.getStatus(), null, e.getCreatedAt())).toList();
        OrderDto.SlotSnapshot w = o.getSlotDate() == null ? null : new OrderDto.SlotSnapshot(o.getSlotDate(), o.getSlotStart(), o.getSlotEnd());
        return new Tracking(o.getId(), o.getNumber(), o.getStatus(), w, false, null, cv, tl);
    }

    static String mask(String phone) {
        if (phone == null || phone.length() < 4) return null;
        return phone.substring(0, Math.min(2, phone.length())) + "•••••" + phone.substring(phone.length() - 2);
    }
}
