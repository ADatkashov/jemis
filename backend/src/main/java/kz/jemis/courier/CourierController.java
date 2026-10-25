package kz.jemis.courier;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import kz.jemis.order.Order;
import kz.jemis.order.OrderRepository;
import kz.jemis.order.OrderStatus;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import kz.jemis.identity.AuthUser;

/** Courier role API. Access is enforced in SecurityConfig (/courier/** requires ROLE_COURIER). */
@RestController
@RequestMapping("/api/v1/courier")
public class CourierController {
    public record AssignmentDto(UUID assignmentId, CourierAssignment.Status status, UUID orderId, String orderNumber,
                                OrderStatus orderStatus, String city, String street, String house, String apartment,
                                String entrance, String floor, String intercom, String instructions, String recipientName,
                                String recipientPhone, long totalMinor, boolean collectCash, int itemCount) {}
    public record StatusBody(@NotNull OrderStatus status) {}
    public record IssueBody(@NotBlank @Size(max = 500) String description) {}
    public record ConsentBody(boolean enabled) {}
    public record LocationBody(@NotNull @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
                               @NotNull @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude) {}

    private final CourierService service;
    private final CourierAssignmentRepository assignments;
    private final OrderRepository orders;

    public CourierController(CourierService service, CourierAssignmentRepository assignments, OrderRepository orders) {
        this.service = service;
        this.assignments = assignments;
        this.orders = orders;
    }

    @GetMapping("/assignments")
    @Transactional(readOnly = true)
    public List<AssignmentDto> mine(@AuthenticationPrincipal AuthUser me) {
        Courier c = service.byUser(me.id());
        return assignments.findByCourierIdAndStatusInOrderByCreatedAtDesc(c.getId(),
                List.of(CourierAssignment.Status.OFFERED, CourierAssignment.Status.ACCEPTED)).stream().map(a -> {
            Order o = orders.findById(a.getOrderId()).orElseThrow();
            return new AssignmentDto(a.getId(), a.getStatus(), o.getId(), o.getNumber(), o.getStatus(), o.getAddrCity(),
                    o.getAddrStreet(), o.getAddrHouse(), o.getAddrApartment(), o.getAddrEntrance(), o.getAddrFloor(),
                    o.getAddrIntercom(), o.getInstructions(), o.getRecipientName(), o.getRecipientPhone(), o.getTotalMinor(),
                    o.getPaymentMethod() == kz.jemis.order.PaymentMethod.CASH
                            && o.getPaymentStatus() == kz.jemis.payment.PaymentStatus.PENDING, o.getItems().size());
        }).toList();
    }

    @PostMapping("/assignments/{id}/accept")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void accept(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) { service.accept(me.id(), id); }

    @PostMapping("/assignments/{id}/reject")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) { service.reject(me.id(), id); }

    @PostMapping("/orders/{orderId}/status")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void status(@AuthenticationPrincipal AuthUser me, @PathVariable UUID orderId, @Valid @RequestBody StatusBody b) {
        service.updateStatus(me.id(), orderId, b.status());
    }

    @PostMapping("/orders/{orderId}/issues")
    @ResponseStatus(HttpStatus.CREATED)
    public void issue(@AuthenticationPrincipal AuthUser me, @PathVariable UUID orderId, @Valid @RequestBody IssueBody b) {
        service.reportIssue(me.id(), orderId, b.description());
    }

    @PutMapping("/tracking-consent")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void consent(@AuthenticationPrincipal AuthUser me, @RequestBody ConsentBody b) { service.setConsent(me.id(), b.enabled()); }

    @PutMapping("/location")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void location(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody LocationBody b) {
        service.updateLocation(me.id(), b.latitude(), b.longitude());
    }
}
