package kz.jemis.cart;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;
import kz.jemis.address.AddressRepository;
import kz.jemis.catalog.Product;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.common.ApiException;
import kz.jemis.identity.AuthUser;
import kz.jemis.pricing.PricingService;
import kz.jemis.pricing.Quote;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/cart")
public class CartController {
    public record SetQuantity(@NotNull @Min(1) Long quantityMilli) {}

    private final CartItemRepository items;
    private final ProductRepository products;
    private final AddressRepository addresses;
    private final PricingService pricing;

    public CartController(CartItemRepository items, ProductRepository products, AddressRepository addresses,
                          PricingService pricing) {
        this.items = items;
        this.products = products;
        this.addresses = addresses;
        this.pricing = pricing;
    }

    /** The cart with server-side prices; optional address / promo code preview delivery fee and discount. */
    @GetMapping
    @Transactional(readOnly = true)
    public Quote get(@AuthenticationPrincipal AuthUser me, @RequestParam(required = false) UUID addressId,
                     @RequestParam(required = false) String promoCode) {
        return quote(me, addressId, promoCode);
    }

    @PutMapping("/items/{productId}")
    @Transactional
    public Quote setQuantity(@AuthenticationPrincipal AuthUser me, @PathVariable UUID productId,
                             @Valid @RequestBody SetQuantity r) {
        Product p = products.findById(productId).filter(Product::isActive)
                .orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found"));
        if (!p.isAvailable()) throw ApiException.conflict("PRODUCT_UNAVAILABLE", "Product is out of stock");
        long q = r.quantityMilli();
        if (q % p.getStepMilli() != 0) {
            throw ApiException.badRequest("INVALID_QUANTITY_STEP", "Quantity must be a multiple of " + p.getStepMilli() + " milli-units");
        }
        if (q > p.availableMilli()) throw ApiException.conflict("INSUFFICIENT_STOCK", "Not enough stock");
        CartItem ci = items.findByUserIdAndProductId(me.id(), productId).orElseGet(() -> {
            CartItem n = new CartItem();
            n.setUserId(me.id());
            n.setProductId(productId);
            return n;
        });
        ci.setQuantityMilli(q);
        items.save(ci);
        return quote(me, null, null);
    }

    @DeleteMapping("/items/{productId}")
    @Transactional
    public Quote remove(@AuthenticationPrincipal AuthUser me, @PathVariable UUID productId) {
        items.findByUserIdAndProductId(me.id(), productId).ifPresent(items::delete);
        items.flush();
        return quote(me, null, null);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void clear(@AuthenticationPrincipal AuthUser me) { items.deleteByUserId(me.id()); }

    private Quote quote(AuthUser me, UUID addressId, String promoCode) {
        String city = null;
        if (addressId != null) {
            city = addresses.findByIdAndUserIdAndDeletedAtIsNull(addressId, me.id())
                    .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "Address not found")).getCity();
        }
        List<CartItem> list = items.findByUserIdOrderByCreatedAt(me.id());
        return pricing.price(list, new PricingService.Request(city, null, promoCode, me.id()), true).quote();
    }
}
