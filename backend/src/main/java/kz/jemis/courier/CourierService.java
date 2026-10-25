package kz.jemis.courier;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.order.Order;
import kz.jemis.order.OrderRepository;
import kz.jemis.order.OrderService;
import kz.jemis.order.OrderStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CourierService {
    private static final Set<OrderStatus> COURIER_STATUSES = Set.of(OrderStatus.PICKED_UP, OrderStatus.ON_THE_WAY, OrderStatus.DELIVERED);

    private final CourierRepository couriers;
    private final CourierAssignmentRepository assignments;
    private final DeliveryIssueRepository issues;
    private final OrderRepository orders;
    private final OrderService orderService;

    public CourierService(CourierRepository couriers, CourierAssignmentRepository assignments,
                          DeliveryIssueRepository issues, OrderRepository orders, OrderService orderService) {
        this.couriers = couriers;
        this.assignments = assignments;
        this.issues = issues;
        this.orders = orders;
        this.orderService = orderService;
    }

    public Courier byUser(UUID userId) {
        return couriers.findByUserId(userId).filter(Courier::isActive)
                .orElseThrow(() -> ApiException.forbidden("NOT_A_COURIER", "No active courier profile"));
    }

    /** Operator offers a ready order to a courier; the courier must accept before the order is assigned. */
    @Transactional
    public CourierAssignment offer(UUID orderId, UUID courierId) {
        Order o = orders.findById(orderId).orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        if (o.getStatus() != OrderStatus.READY_FOR_DELIVERY) {
            throw ApiException.conflict("ORDER_NOT_READY", "Order must be READY_FOR_DELIVERY to assign a courier");
        }
        couriers.findById(courierId).filter(Courier::isActive)
                .orElseThrow(() -> ApiException.notFound("COURIER_NOT_FOUND", "Courier not found"));
        assignments.findByOrderIdAndStatusIn(orderId, List.of(CourierAssignment.Status.OFFERED, CourierAssignment.Status.ACCEPTED))
                .ifPresent(a -> { a.setStatus(CourierAssignment.Status.CANCELLED); assignments.flush(); });
        CourierAssignment a = new CourierAssignment();
        a.setOrderId(orderId);
        a.setCourierId(courierId);
        return assignments.save(a);
    }

    @Transactional
    public void accept(UUID courierUserId, UUID assignmentId) {
        Courier c = byUser(courierUserId);
        CourierAssignment a = assignments.findByIdAndCourierId(assignmentId, c.getId())
                .orElseThrow(() -> ApiException.notFound("ASSIGNMENT_NOT_FOUND", "Assignment not found"));
        if (a.getStatus() != CourierAssignment.Status.OFFERED) throw ApiException.conflict("ASSIGNMENT_NOT_OFFERED", "Assignment is not pending");
        Order o = orders.findById(a.getOrderId()).orElseThrow();
        a.setStatus(CourierAssignment.Status.ACCEPTED);
        o.setCourierId(c.getId());
        orderService.transition(o, OrderStatus.ASSIGNED_TO_COURIER, courierUserId, "courier accepted");
    }

    @Transactional
    public void reject(UUID courierUserId, UUID assignmentId) {
        Courier c = byUser(courierUserId);
        CourierAssignment a = assignments.findByIdAndCourierId(assignmentId, c.getId())
                .orElseThrow(() -> ApiException.notFound("ASSIGNMENT_NOT_FOUND", "Assignment not found"));
        if (a.getStatus() != CourierAssignment.Status.OFFERED) throw ApiException.conflict("ASSIGNMENT_NOT_OFFERED", "Assignment is not pending");
        a.setStatus(CourierAssignment.Status.REJECTED);
    }

    @Transactional
    public Order updateStatus(UUID courierUserId, UUID orderId, OrderStatus to) {
        Courier c = byUser(courierUserId);
        if (!COURIER_STATUSES.contains(to)) throw ApiException.badRequest("STATUS_NOT_ALLOWED", "Couriers may only set PICKED_UP, ON_THE_WAY or DELIVERED");
        Order o = orders.findById(orderId).filter(x -> c.getId().equals(x.getCourierId()))
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        orderService.transition(o, to, courierUserId, "courier");
        if (to == OrderStatus.DELIVERED) {
            assignments.findByOrderIdAndStatusIn(orderId, List.of(CourierAssignment.Status.ACCEPTED))
                    .ifPresent(a -> a.setStatus(CourierAssignment.Status.COMPLETED));
        }
        return o;
    }

    @Transactional
    public void reportIssue(UUID courierUserId, UUID orderId, String description) {
        Courier c = byUser(courierUserId);
        orders.findById(orderId).filter(x -> c.getId().equals(x.getCourierId()))
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        DeliveryIssue i = new DeliveryIssue();
        i.setOrderId(orderId);
        i.setCourierId(c.getId());
        i.setDescription(description);
        issues.save(i);
    }

    @Transactional
    public void setConsent(UUID courierUserId, boolean enabled) {
        Courier c = byUser(courierUserId);
        c.setTrackingConsent(enabled);
        if (!enabled) { c.setLastLat(null); c.setLastLng(null); c.setLastLocationAt(null); }
    }

    @Transactional
    public void updateLocation(UUID courierUserId, BigDecimal lat, BigDecimal lng) {
        Courier c = byUser(courierUserId);
        if (!c.isTrackingConsent()) throw ApiException.forbidden("TRACKING_CONSENT_REQUIRED", "Location sharing has not been enabled");
        c.setLastLat(lat);
        c.setLastLng(lng);
        c.setLastLocationAt(Instant.now());
    }
}
