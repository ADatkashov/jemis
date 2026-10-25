package kz.jemis.order;

import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import kz.jemis.address.Address;
import kz.jemis.address.AddressRepository;
import kz.jemis.cart.CartItem;
import kz.jemis.cart.CartItemRepository;
import kz.jemis.catalog.Product;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.common.ApiException;
import kz.jemis.common.I18n;
import kz.jemis.common.SettingsService;
import kz.jemis.courier.CourierAssignment;
import kz.jemis.courier.CourierAssignmentRepository;
import kz.jemis.delivery.DeliveryService;
import kz.jemis.delivery.SlotTemplate;
import kz.jemis.notification.NotificationService;
import kz.jemis.payment.CashProvider;
import kz.jemis.payment.Payment;
import kz.jemis.payment.PaymentProviders;
import kz.jemis.payment.PaymentRepository;
import kz.jemis.payment.PaymentStatus;
import kz.jemis.pricing.PricingService;
import kz.jemis.pricing.Quote;
import kz.jemis.promotion.PromoService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
    public record CheckoutRequest(UUID addressId, UUID slotTemplateId, LocalDate slotDate, boolean immediate,
                                  String promoCode, PaymentMethod paymentMethod, Long expectedTotalMinor) {}
    public record ReorderResult(Quote cart, List<UUID> skippedProductIds) {}

    private final OrderRepository orders;
    private final OrderEventRepository events;
    private final CartItemRepository cart;
    private final AddressRepository addresses;
    private final ProductRepository products;
    private final PricingService pricing;
    private final DeliveryService delivery;
    private final PromoService promos;
    private final PaymentRepository payments;
    private final PaymentProviders providers;
    private final SettingsService settings;
    private final NotificationService notifications;
    private final CourierAssignmentRepository assignments;
    private final EntityManager em;
    private final Clock clock;
    private final Set<OrderStatus> customerCancellable;

    public OrderService(OrderRepository orders, OrderEventRepository events, CartItemRepository cart,
                        AddressRepository addresses, ProductRepository products, PricingService pricing,
                        DeliveryService delivery, PromoService promos, PaymentRepository payments,
                        PaymentProviders providers, SettingsService settings, NotificationService notifications,
                        CourierAssignmentRepository assignments, EntityManager em, Clock clock,
                        @Value("${jemis.orders.customer-cancellable}") List<OrderStatus> customerCancellable) {
        this.orders = orders;
        this.events = events;
        this.cart = cart;
        this.addresses = addresses;
        this.products = products;
        this.pricing = pricing;
        this.delivery = delivery;
        this.promos = promos;
        this.payments = payments;
        this.providers = providers;
        this.settings = settings;
        this.notifications = notifications;
        this.assignments = assignments;
        this.em = em;
        this.clock = clock;
        this.customerCancellable = Set.copyOf(customerCancellable);
    }

    /** Price preview for the checkout review step (no side effects, no capacity check). */
    @Transactional(readOnly = true)
    public Quote quote(UUID userId, UUID addressId, UUID slotTemplateId, String promoCode) {
        Address a = addresses.findByIdAndUserIdAndDeletedAtIsNull(addressId, userId)
                .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "Address not found"));
        Long extra = null;
        if (slotTemplateId != null) {
            extra = em.find(SlotTemplate.class, slotTemplateId) == null ? null : em.find(SlotTemplate.class, slotTemplateId).getExtraFeeMinor();
        }
        return pricing.price(cart.findByUserIdOrderByCreatedAt(userId),
                new PricingService.Request(a.getCity(), extra, promoCode, userId), true).quote();
    }

    @Transactional
    public Order checkout(UUID userId, CheckoutRequest r, String idempotencyKey) {
        // Serialise requests carrying the same key so a retry waits for the first one and then replays it.
        advisoryLock("idem:" + userId + ":" + idempotencyKey);
        var existing = orders.findByUserIdAndIdempotencyKey(userId, idempotencyKey);
        if (existing.isPresent()) return existing.get();

        List<CartItem> items = cart.findByUserIdOrderByCreatedAt(userId);
        if (items.isEmpty()) throw ApiException.badRequest("EMPTY_CART", "Cart is empty");
        Address addr = addresses.findByIdAndUserIdAndDeletedAtIsNull(r.addressId(), userId)
                .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "Address not found"));
        PaymentMethod method = r.paymentMethod() == null ? PaymentMethod.CASH : r.paymentMethod();
        if (method == PaymentMethod.CASH && !settings.getBool("payment.cash_enabled", true)) {
            throw ApiException.badRequest("PAYMENT_METHOD_UNAVAILABLE", "Payment method is not available");
        }
        if (method == PaymentMethod.ONLINE && providers.onlineDefault().isEmpty()) {
            throw ApiException.badRequest("PAYMENT_METHOD_UNAVAILABLE", "Online payment is not configured");
        }

        SlotTemplate slot = null;
        if (r.immediate()) {
            if (!settings.getBool("delivery.immediate_enabled", false)) {
                throw ApiException.badRequest("IMMEDIATE_DELIVERY_DISABLED", "Immediate delivery is not available");
            }
        } else {
            if (r.slotTemplateId() == null || r.slotDate() == null) {
                throw ApiException.badRequest("SLOT_REQUIRED", "Delivery slot is required");
            }
            slot = delivery.reserveSlot(r.slotTemplateId(), r.slotDate());
        }

        // Lock product rows (sorted) BEFORE pricing so prices and stock are read under the lock.
        List<UUID> ids = items.stream().map(CartItem::getProductId).sorted().toList();
        List<Product> locked = products.lockAllById(ids);
        Map<UUID, Product> byId = locked.stream().collect(Collectors.toMap(Product::getId, p -> p));

        PricingService.Priced priced = pricing.price(items, new PricingService.Request(addr.getCity(),
                slot == null ? 0L : slot.getExtraFeeMinor(), r.promoCode(), userId), I18n.lang(), false);
        Quote q = priced.quote();
        if (q.checkoutBlocked()) {
            throw ApiException.conflict("CHECKOUT_BLOCKED", "Cart cannot be checked out", Map.of("issues", q.issues(),
                    "items", q.lines().stream().filter(l -> l.issue() != null).map(Quote.Line::productId).toList()));
        }
        if (r.expectedTotalMinor() != null && r.expectedTotalMinor() != q.totalMinor()) {
            throw ApiException.conflict("PRICE_CHANGED", "Prices changed, please review the order",
                    Map.of("totalMinor", q.totalMinor()));
        }

        Order o = new Order();
        o.setNumber("JM-" + ((Number) em.createNativeQuery("select nextval('order_number_seq')").getSingleResult()).longValue());
        o.setUserId(userId);
        o.setIdempotencyKey(idempotencyKey);
        o.setPaymentMethod(method);
        o.setPaymentStatus(PaymentStatus.PENDING);
        o.setAddrCity(addr.getCity());
        o.setAddrStreet(addr.getStreet());
        o.setAddrHouse(addr.getHouse());
        o.setAddrApartment(addr.getApartment());
        o.setAddrEntrance(addr.getEntrance());
        o.setAddrFloor(addr.getFloor());
        o.setAddrIntercom(addr.getIntercom());
        o.setAddrLatitude(addr.getLatitude());
        o.setAddrLongitude(addr.getLongitude());
        o.setRecipientName(addr.getRecipientName() != null && !addr.getRecipientName().isBlank() ? addr.getRecipientName()
                : (String) em.createNativeQuery("select full_name from users where id = :u").setParameter("u", userId).getSingleResult());
        o.setRecipientPhone(addr.getRecipientPhone());
        o.setInstructions(addr.getInstructions());
        o.setImmediate(r.immediate());
        if (slot != null) {
            o.setSlotTemplateId(slot.getId());
            o.setSlotDate(r.slotDate());
            o.setSlotStart(slot.getStartTime());
            o.setSlotEnd(slot.getEndTime());
        }
        o.setSubtotalMinor(q.subtotalMinor());
        o.setDiscountMinor(q.discountMinor());
        o.setDeliveryFeeMinor(q.deliveryFeeMinor());
        o.setServiceFeeMinor(q.serviceFeeMinor());
        o.setTotalMinor(q.totalMinor());
        o.setPromoCode(q.promoCode());
        o.setStatus(method == PaymentMethod.CASH ? OrderStatus.CONFIRMED : OrderStatus.PENDING_PAYMENT);
        for (Quote.Line l : q.lines()) {
            Product p = byId.get(l.productId());
            OrderItem oi = new OrderItem();
            oi.setProductId(p.getId());
            oi.setSku(p.getSku());
            oi.setNameRu(p.getNameRu());
            oi.setNameKk(p.getNameKk());
            oi.setNameEn(p.getNameEn());
            oi.setUnit(p.getUnit());
            oi.setImageUrl(p.getImageUrl());
            oi.setUnitPriceMinor(l.unitPriceMinor());
            oi.setQuantityMilli(l.quantityMilli());
            oi.setLineTotalMinor(l.lineTotalMinor());
            o.getItems().add(oi);
            p.setReservedMilli(p.getReservedMilli() + l.quantityMilli());
            p.setPopularity(p.getPopularity() + 1);
        }
        orders.saveAndFlush(o);
        if (priced.promotion() != null) promos.redeem(priced.promotion(), userId, o.getId());
        if (method == PaymentMethod.CASH) {
            Payment pay = new Payment();
            pay.setOrderId(o.getId());
            pay.setProvider(CashProvider.KEY);
            pay.setAmountMinor(o.getTotalMinor());
            payments.save(pay);
        }
        recordEvent(o, o.getStatus(), userId, null);
        if (o.getStatus() == OrderStatus.CONFIRMED) notifications.orderEvent(userId, "ORDER_CONFIRMED", o.getNumber(), o.getId());
        cart.deleteByUserId(userId);
        return o;
    }

    @Transactional
    public Order transition(Order o, OrderStatus to, UUID actorId, String note) {
        OrderStatus from = o.getStatus();
        if (!from.canTransitionTo(to)) {
            throw ApiException.conflict("INVALID_TRANSITION", "Cannot change status from " + from + " to " + to,
                    Map.of("from", from.name(), "to", to.name(), "allowed", from.next().stream().map(Enum::name).sorted().toList()));
        }
        switch (to) {
            case CANCELLED -> cancelSideEffects(o);
            case PICKED_UP -> commitStock(o);
            case DELIVERED -> {
                if (o.getPaymentMethod() == PaymentMethod.CASH && o.getPaymentStatus() == PaymentStatus.PENDING) {
                    payments.findByOrderIdAndStatus(o.getId(), PaymentStatus.PENDING).ifPresent(p -> p.setStatus(PaymentStatus.SUCCEEDED));
                    o.setPaymentStatus(PaymentStatus.SUCCEEDED);
                    o.setPaidAt(Instant.now(clock));
                }
            }
            case REFUNDED -> {
                if (o.getPaymentStatus() != PaymentStatus.SUCCEEDED) {
                    throw ApiException.conflict("ORDER_NOT_PAID", "Only a paid order can be refunded");
                }
                o.setPaymentStatus(PaymentStatus.REFUNDED);
            }
            case READY_FOR_DELIVERY -> {
                if (from == OrderStatus.ASSIGNED_TO_COURIER) {
                    assignments.findByOrderIdAndStatusIn(o.getId(), List.of(CourierAssignment.Status.ACCEPTED, CourierAssignment.Status.OFFERED))
                            .ifPresent(a -> a.setStatus(CourierAssignment.Status.CANCELLED));
                    o.setCourierId(null);
                }
            }
            default -> { }
        }
        o.setStatus(to);
        recordEvent(o, to, actorId, note);
        String type = switch (to) {
            case CONFIRMED -> "ORDER_CONFIRMED";
            case PREPARING -> "ORDER_PREPARING";
            case ASSIGNED_TO_COURIER -> "COURIER_ASSIGNED";
            case ON_THE_WAY -> "ORDER_ON_THE_WAY";
            case DELIVERED -> "ORDER_DELIVERED";
            case CANCELLED -> "ORDER_CANCELLED";
            default -> null;
        };
        if (type != null && !(to == OrderStatus.CONFIRMED && from != OrderStatus.PENDING_PAYMENT)) {
            notifications.orderEvent(o.getUserId(), type, o.getNumber(), o.getId());
        }
        return o;
    }

    @Transactional
    public Order cancelByCustomer(UUID userId, UUID orderId) {
        Order o = orders.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        if (!customerCancellable.contains(o.getStatus())) {
            throw ApiException.conflict("ORDER_NOT_CANCELLABLE", "Order can no longer be cancelled");
        }
        return transition(o, OrderStatus.CANCELLED, userId, "cancelled by customer");
    }

    /** Called by the expiry job: cancels an unpaid online order and releases its reserved stock. */
    @Transactional
    public void cancelIfStillUnpaid(UUID orderId) {
        orders.findById(orderId).filter(o -> o.getStatus() == OrderStatus.PENDING_PAYMENT)
                .ifPresent(o -> transition(o, OrderStatus.CANCELLED, null, "payment timeout"));
    }

    @Transactional
    public ReorderResult reorder(UUID userId, UUID orderId) {
        Order o = orders.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        List<UUID> skipped = new ArrayList<>();
        Map<UUID, Product> byId = products.findAllById(o.getItems().stream().map(OrderItem::getProductId).toList()).stream()
                .collect(Collectors.toMap(Product::getId, p -> p));
        for (OrderItem i : o.getItems()) {
            Product p = byId.get(i.getProductId());
            if (p == null || !p.isAvailable()) { skipped.add(i.getProductId()); continue; }
            CartItem ci = cart.findByUserIdAndProductId(userId, p.getId()).orElseGet(() -> {
                CartItem n = new CartItem();
                n.setUserId(userId);
                n.setProductId(p.getId());
                return n;
            });
            long wanted = ci.getQuantityMilli() + i.getQuantityMilli();
            long capped = Math.min(wanted, p.availableMilli() - p.availableMilli() % p.getStepMilli());
            if (capped <= 0) { skipped.add(p.getId()); continue; }
            ci.setQuantityMilli(capped);
            cart.save(ci);
        }
        cart.flush();
        Quote q = pricing.price(cart.findByUserIdOrderByCreatedAt(userId), new PricingService.Request(null, null, null, userId), true).quote();
        return new ReorderResult(q, skipped);
    }

    @Transactional(readOnly = true)
    public Page<Order> list(UUID userId, int page, int size) {
        return orders.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 50)));
    }

    @Transactional(readOnly = true)
    public OrderDto detail(UUID userId, UUID orderId) {
        Order o = orders.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> ApiException.notFound("ORDER_NOT_FOUND", "Order not found"));
        return toDto(o);
    }

    public OrderDto toDto(Order o) {
        return OrderDto.of(o, events.findByOrderIdOrderByCreatedAt(o.getId()), I18n.lang(), customerCancellable.contains(o.getStatus()));
    }

    private void cancelSideEffects(Order o) {
        releaseStock(o);
        promos.releaseForOrder(o.getId());
        for (Payment p : payments.findByOrderIdOrderByCreatedAtDesc(o.getId())) {
            if (p.getStatus() == PaymentStatus.PENDING) p.setStatus(PaymentStatus.CANCELLED);
        }
        if (o.getPaymentStatus() == PaymentStatus.PENDING || o.getPaymentStatus() == PaymentStatus.FAILED) {
            o.setPaymentStatus(PaymentStatus.CANCELLED);
        }
        assignments.findByOrderIdAndStatusIn(o.getId(), List.of(CourierAssignment.Status.ACCEPTED, CourierAssignment.Status.OFFERED))
                .ifPresent(a -> a.setStatus(CourierAssignment.Status.CANCELLED));
        o.setCourierId(null);
    }

    private void releaseStock(Order o) {
        if (o.isStockCommitted()) return;
        Map<UUID, Long> qty = o.getItems().stream().collect(Collectors.toMap(OrderItem::getProductId, OrderItem::getQuantityMilli, Long::sum));
        for (Product p : products.lockAllById(new HashSet<>(qty.keySet()))) {
            p.setReservedMilli(Math.max(0, p.getReservedMilli() - qty.get(p.getId())));
        }
    }

    private void commitStock(Order o) {
        if (o.isStockCommitted()) return;
        Map<UUID, Long> qty = o.getItems().stream().collect(Collectors.toMap(OrderItem::getProductId, OrderItem::getQuantityMilli, Long::sum));
        for (Product p : products.lockAllById(new HashSet<>(qty.keySet()))) {
            long q = qty.get(p.getId());
            p.setStockMilli(Math.max(0, p.getStockMilli() - q));
            p.setReservedMilli(Math.max(0, p.getReservedMilli() - q));
        }
        o.setStockCommitted(true);
    }

    private void recordEvent(Order o, OrderStatus status, UUID actor, String note) {
        OrderEvent e = new OrderEvent();
        e.setOrderId(o.getId());
        e.setStatus(status);
        e.setActorId(actor);
        e.setNote(note);
        events.save(e);
    }

    private void advisoryLock(String key) {
        em.createNativeQuery("select pg_advisory_xact_lock(hashtext(:k))").setParameter("k", key).getSingleResult();
    }
}
