package kz.jemis.admin;

import jakarta.persistence.criteria.Predicate;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.AuditService;
import kz.jemis.common.I18n;
import kz.jemis.common.PageResponse;
import kz.jemis.courier.Courier;
import kz.jemis.courier.CourierRepository;
import kz.jemis.courier.CourierService;
import kz.jemis.courier.DeliveryIssue;
import kz.jemis.courier.DeliveryIssueRepository;
import kz.jemis.identity.AuthUser;
import kz.jemis.order.Order;
import kz.jemis.order.OrderDto;
import kz.jemis.order.OrderRepository;
import kz.jemis.order.OrderService;
import kz.jemis.order.OrderStatus;
import kz.jemis.payment.Payment;
import kz.jemis.payment.PaymentRepository;
import kz.jemis.payment.PaymentService;
import kz.jemis.payment.PaymentStatus;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/orders")
public class AdminOrderController {
    public record AdminOrderSummary(UUID id, String number, OrderStatus status, PaymentStatus paymentStatus,
                                    String recipientName, long totalMinor, Instant createdAt) {}
    public record PaymentRow(UUID id, String provider, PaymentStatus status, long amountMinor, String failureReason, Instant createdAt) {}
    public record IssueRow(String description, Instant createdAt) {}
    public record CourierRef(UUID id, String name, String phone) {}
    public record AdminOrderDetail(OrderDto order, String operatorNotes, UUID customerId, String recipientPhone,
                                   CourierRef courier, List<PaymentRow> payments, List<IssueRow> issues, List<OrderStatus> allowedNext) {}
    public record StatusBody(@NotNull OrderStatus status, @Size(max = 500) String note) {}
    public record AssignBody(@NotNull UUID courierId) {}
    public record NotesBody(@NotBlank @Size(max = 4000) String notes) {}

    private final OrderRepository orders;
    private final OrderService orderService;
    private final PaymentService paymentService;
    private final PaymentRepository payments;
    private final CourierService courierService;
    private final CourierRepository couriers;
    private final DeliveryIssueRepository issues;
    private final AuditService audit;

    public AdminOrderController(OrderRepository orders, OrderService orderService, PaymentService paymentService,
                                PaymentRepository payments, CourierService courierService, CourierRepository couriers,
                                DeliveryIssueRepository issues, AuditService audit) {
        this.orders = orders;
        this.orderService = orderService;
        this.paymentService = paymentService;
        this.payments = payments;
        this.courierService = courierService;
        this.couriers = couriers;
        this.issues = issues;
        this.audit = audit;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public PageResponse<AdminOrderSummary> list(@RequestParam(required = false) OrderStatus status,
                                                @RequestParam(required = false) PaymentStatus paymentStatus,
                                                @RequestParam(required = false) String q,
                                                @RequestParam(required = false) Instant from,
                                                @RequestParam(required = false) Instant to,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "25") int size) {
        var spec = (org.springframework.data.jpa.domain.Specification<Order>) (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (status != null) p.add(cb.equal(root.get("status"), status));
            if (paymentStatus != null) p.add(cb.equal(root.get("paymentStatus"), paymentStatus));
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThan(root.get("createdAt"), to));
            if (q != null && !q.isBlank()) {
                String like = "%" + q.trim().toLowerCase().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
                p.add(cb.or(cb.like(cb.lower(root.get("number")), like, '\\'),
                        cb.like(cb.lower(root.get("recipientName")), like, '\\'),
                        cb.like(cb.coalesce(root.<String>get("recipientPhone"), ""), like, '\\')));
            }
            return cb.and(p.toArray(new Predicate[0]));
        };
        return PageResponse.of(orders.findAll(spec, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100),
                Sort.by("createdAt").descending())),
                o -> new AdminOrderSummary(o.getId(), o.getNumber(), o.getStatus(), o.getPaymentStatus(), o.getRecipientName(),
                        o.getTotalMinor(), o.getCreatedAt()));
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public AdminOrderDetail get(@PathVariable UUID id) { return detail(find(id)); }

    /** Operator status change through the server-side state machine (REFUNDED and ASSIGNED have dedicated endpoints). */
    @PostMapping("/{id}/status")
    @Transactional
    public AdminOrderDetail status(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody StatusBody b) {
        if (b.status() == OrderStatus.REFUNDED) throw ApiException.badRequest("USE_REFUND_ENDPOINT", "Use POST /refund to refund an order");
        if (b.status() == OrderStatus.ASSIGNED_TO_COURIER) throw ApiException.badRequest("USE_ASSIGN_ENDPOINT", "Use POST /assign to offer the order to a courier");
        Order o = find(id);
        OrderStatus from = o.getStatus();
        orderService.transition(o, b.status(), me.id(), b.note());
        audit.record(me.id(), "ORDER_STATUS", "order", id, from + "->" + b.status());
        return detail(o);
    }

    @PostMapping("/{id}/assign")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public AdminOrderDetail assign(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody AssignBody b) {
        courierService.offer(id, b.courierId());
        audit.record(me.id(), "ORDER_ASSIGN_OFFER", "order", id, "courier " + b.courierId());
        return detail(find(id));
    }

    @PostMapping("/{id}/notes")
    @Transactional
    public AdminOrderDetail notes(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody NotesBody b) {
        Order o = find(id);
        o.setOperatorNotes(b.notes());
        audit.record(me.id(), "ORDER_NOTE", "order", id, null);
        return detail(o);
    }

    @PostMapping("/{id}/refund")
    @Transactional
    public AdminOrderDetail refund(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        paymentService.refund(id, me.id());
        return detail(find(id));
    }

    private Order find(UUID id) {
        return orders.findById(id).orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
    }

    private AdminOrderDetail detail(Order o) {
        Courier c = o.getCourierId() == null ? null : couriers.findById(o.getCourierId()).orElse(null);
        return new AdminOrderDetail(orderService.toDto(o), o.getOperatorNotes(), o.getUserId(), o.getRecipientPhone(),
                c == null ? null : new CourierRef(c.getId(), c.getDisplayName(), c.getPhone()),
                payments.findByOrderIdOrderByCreatedAtDesc(o.getId()).stream()
                        .map((Payment p) -> new PaymentRow(p.getId(), p.getProvider(), p.getStatus(), p.getAmountMinor(), p.getFailureReason(), p.getCreatedAt())).toList(),
                issues.findByOrderIdOrderByCreatedAtDesc(o.getId()).stream().map((DeliveryIssue i) -> new IssueRow(i.getDescription(), i.getCreatedAt())).toList(),
                o.getStatus().next().stream().filter(s -> s != OrderStatus.REFUNDED && s != OrderStatus.ASSIGNED_TO_COURIER).sorted().toList());
    }
}
