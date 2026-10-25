package kz.jemis.order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kz.jemis.catalog.ProductDto;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.common.ApiException;
import kz.jemis.common.I18n;
import kz.jemis.common.PageResponse;
import kz.jemis.identity.AuthUser;
import kz.jemis.pricing.Quote;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class OrderController {
    public record QuoteRequest(@NotNull UUID addressId, UUID slotTemplateId, @Size(max = 40) String promoCode) {}
    public record CheckoutBody(@NotNull UUID addressId, UUID slotTemplateId, LocalDate slotDate, boolean immediate,
                               @Size(max = 40) String promoCode, PaymentMethod paymentMethod, Long expectedTotalMinor) {}

    private final OrderService orders;
    private final OrderRepository repo;
    private final ProductRepository products;

    public OrderController(OrderService orders, OrderRepository repo, ProductRepository products) {
        this.orders = orders;
        this.repo = repo;
        this.products = products;
    }

    @PostMapping("/checkout/quote")
    public Quote quote(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody QuoteRequest r) {
        return orders.quote(me.id(), r.addressId(), r.slotTemplateId(), r.promoCode());
    }

    /** Creates the order. The Idempotency-Key header makes retries and double taps safe. */
    @PostMapping("/checkout")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public OrderDto checkout(@AuthenticationPrincipal AuthUser me,
                             @RequestHeader("Idempotency-Key") @NotBlank @Size(max = 80) String key,
                             @Valid @RequestBody CheckoutBody b) {
        Order o = orders.checkout(me.id(), new OrderService.CheckoutRequest(b.addressId(), b.slotTemplateId(),
                b.slotDate(), b.immediate(), b.promoCode(), b.paymentMethod(), b.expectedTotalMinor()), key);
        return orders.toDto(o);
    }

    @GetMapping("/orders")
    @Transactional(readOnly = true)
    public PageResponse<OrderDto.Summary> list(@AuthenticationPrincipal AuthUser me,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(orders.list(me.id(), page, size), OrderDto.Summary::of);
    }

    @GetMapping("/orders/{id}")
    @Transactional(readOnly = true)
    public OrderDto get(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) { return orders.detail(me.id(), id); }

    @PostMapping("/orders/{id}/cancel")
    @Transactional
    public OrderDto cancel(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        return orders.toDto(orders.cancelByCustomer(me.id(), id));
    }

    @PostMapping("/orders/{id}/reorder")
    @Transactional
    public OrderService.ReorderResult reorder(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        return orders.reorder(me.id(), id);
    }

    @GetMapping("/customer/frequent-products")
    @Transactional(readOnly = true)
    public List<ProductDto> frequent(@AuthenticationPrincipal AuthUser me) {
        String lang = I18n.lang();
        List<UUID> ids = repo.frequentProductIds(me.id(), 12);
        return ids.stream().map(products::findById).flatMap(java.util.Optional::stream)
                .filter(p -> p.isActive()).map(p -> ProductDto.of(p, lang, false)).toList();
    }
}
