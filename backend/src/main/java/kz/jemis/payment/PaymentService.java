package kz.jemis.payment;

import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.AuditService;
import kz.jemis.notification.NotificationService;
import kz.jemis.order.Order;
import kz.jemis.order.OrderRepository;
import kz.jemis.order.OrderService;
import kz.jemis.order.OrderStatus;
import kz.jemis.order.PaymentMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    public record PaymentView(UUID id, UUID orderId, String provider, PaymentStatus status, long amountMinor,
                              String currency, String redirectUrl, String note, boolean developmentOnly) {}
    public enum WebhookResult { APPLIED, DUPLICATE, IGNORED }

    private final PaymentRepository payments;
    private final OrderRepository orders;
    private final OrderService orderService;
    private final PaymentProviders providers;
    private final NotificationService notifications;
    private final AuditService audit;
    private final EntityManager em;

    public PaymentService(PaymentRepository payments, OrderRepository orders, OrderService orderService,
                          PaymentProviders providers, NotificationService notifications, AuditService audit,
                          EntityManager em) {
        this.payments = payments;
        this.orders = orders;
        this.orderService = orderService;
        this.providers = providers;
        this.notifications = notifications;
        this.audit = audit;
        this.em = em;
    }

    /** Starts (or returns the already open) payment attempt for an unpaid online order owned by the caller. */
    @Transactional
    public PaymentView initiate(UUID userId, UUID orderId) {
        Order o = orders.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        if (o.getPaymentMethod() != PaymentMethod.ONLINE || o.getStatus() != OrderStatus.PENDING_PAYMENT) {
            throw ApiException.conflict("PAYMENT_NOT_APPLICABLE", "This order does not await online payment");
        }
        var open = payments.findByOrderIdAndStatus(o.getId(), PaymentStatus.PENDING);
        if (open.isPresent()) return view(open.get(), null);
        PaymentProvider provider = providers.onlineDefault()
                .orElseThrow(() -> ApiException.conflict("PAYMENT_METHOD_UNAVAILABLE", "Online payment is not configured"));
        Payment p = new Payment();
        p.setOrderId(o.getId());
        p.setProvider(provider.key());
        p.setAmountMinor(o.getTotalMinor());
        p.setCurrency(o.getCurrency());
        PaymentProvider.InitResult init = provider.initiate(p, o);
        p.setProviderRef(init.providerRef());
        payments.saveAndFlush(p);
        o.setPaymentStatus(PaymentStatus.PENDING);
        return view(p, init);
    }

    /**
     * Applies a provider notification. Order: signature verification (provider) → idempotency (unique event id)
     * → state change under a row lock. The client's own "payment done" signal is never trusted.
     */
    @Transactional
    public WebhookResult handleWebhook(String providerKey, Map<String, String> headers, byte[] body) {
        PaymentProvider provider = providers.get(providerKey).filter(PaymentProvider::isEnabled)
                .orElseThrow(() -> ApiException.notFound("UNKNOWN_PROVIDER", "Unknown provider"));
        PaymentProvider.Event ev = provider.verifyAndParse(headers, body);
        if (ev.eventId() == null || ev.eventId().isBlank() || ev.providerRef() == null || ev.providerRef().isBlank()) {
            throw ApiException.badRequest("INVALID_PAYLOAD", "Malformed notification");
        }
        Payment p = payments.findByProviderRefForUpdate(provider.key(), ev.providerRef()).orElse(null);
        int inserted = em.createNativeQuery("insert into payment_events(provider, event_id, payment_id, type) values (:pr,:e,:p,:t) on conflict do nothing")
                .setParameter("pr", provider.key()).setParameter("e", ev.eventId())
                .setParameter("p", p == null ? null : p.getId()).setParameter("t", ev.type().name()).executeUpdate();
        if (inserted == 0) return WebhookResult.DUPLICATE;
        if (p == null) {
            log.warn("Notification {} for unknown payment reference ignored", ev.eventId());
            return WebhookResult.IGNORED;
        }
        if (p.getStatus() != PaymentStatus.PENDING) return WebhookResult.IGNORED;
        if (ev.type() == PaymentProvider.EventType.SUCCEEDED && ev.amountMinor() != p.getAmountMinor()) {
            log.error("Amount mismatch for payment {}: expected {} got {}", p.getId(), p.getAmountMinor(), ev.amountMinor());
            audit.record(null, "PAYMENT_AMOUNT_MISMATCH", "payment", p.getId(), "event " + ev.eventId());
            return WebhookResult.IGNORED;
        }
        Order o = orders.findById(p.getOrderId()).orElseThrow();
        switch (ev.type()) {
            case SUCCEEDED -> {
                p.setStatus(PaymentStatus.SUCCEEDED);
                o.setPaymentStatus(PaymentStatus.SUCCEEDED);
                o.setPaidAt(Instant.now());
                if (o.getStatus() == OrderStatus.PENDING_PAYMENT) {
                    orderService.transition(o, OrderStatus.CONFIRMED, null, "payment received");
                    notifications.orderEvent(o.getUserId(), "PAYMENT_SUCCEEDED", o.getNumber(), o.getId());
                } else {
                    // Paid after the order was cancelled/expired: money must be returned by an operator.
                    audit.record(null, "PAYMENT_AFTER_CANCEL", "order", o.getId(), "refund required");
                    log.warn("Payment succeeded for order {} in status {}; refund required", o.getNumber(), o.getStatus());
                }
            }
            case FAILED -> {
                p.setStatus(PaymentStatus.FAILED);
                p.setFailureReason(ev.failureReason() == null ? null : ev.failureReason().substring(0, Math.min(200, ev.failureReason().length())));
                if (o.getStatus() == OrderStatus.PENDING_PAYMENT) o.setPaymentStatus(PaymentStatus.FAILED);
                notifications.orderEvent(o.getUserId(), "PAYMENT_FAILED", o.getNumber(), o.getId());
            }
            case CANCELLED -> {
                p.setStatus(PaymentStatus.CANCELLED);
                if (o.getStatus() == OrderStatus.PENDING_PAYMENT) o.setPaymentStatus(PaymentStatus.FAILED);
            }
        }
        return WebhookResult.APPLIED;
    }

    /** Refunds a paid order through its provider, then moves the order to REFUNDED. */
    @Transactional
    public void refund(UUID orderId, UUID actorId) {
        Order o = orders.findById(orderId).orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        if (o.getPaymentStatus() != PaymentStatus.SUCCEEDED) throw ApiException.conflict("ORDER_NOT_PAID", "Only a paid order can be refunded");
        Payment p = payments.findByOrderIdOrderByCreatedAtDesc(o.getId()).stream()
                .filter(x -> x.getStatus() == PaymentStatus.SUCCEEDED).findFirst()
                .orElseThrow(() -> ApiException.conflict("ORDER_NOT_PAID", "No successful payment found"));
        PaymentProvider provider = providers.get(p.getProvider())
                .orElseThrow(() -> ApiException.conflict("PROVIDER_UNAVAILABLE", "Payment provider is unavailable"));
        try {
            provider.refund(p);
        } catch (UnsupportedOperationException e) {
            throw new ApiException(org.springframework.http.HttpStatus.NOT_IMPLEMENTED, "REFUND_NOT_SUPPORTED",
                    "Refunds are not supported by this provider", null);
        }
        p.setStatus(PaymentStatus.REFUNDED);
        orderService.transition(o, OrderStatus.REFUNDED, actorId, "refund");
        audit.record(actorId, "ORDER_REFUND", "order", o.getId(), "provider " + p.getProvider());
    }

    private PaymentView view(Payment p, PaymentProvider.InitResult init) {
        boolean dev = providers.get(p.getProvider()).map(PaymentProvider::developmentOnly).orElse(false);
        return new PaymentView(p.getId(), p.getOrderId(), p.getProvider(), p.getStatus(), p.getAmountMinor(), p.getCurrency(),
                init == null ? null : init.redirectUrl(), init == null ? null : init.note(), dev);
    }
}
