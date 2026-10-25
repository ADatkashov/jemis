package kz.jemis.cart;

import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;
import kz.jemis.catalog.Product;
import kz.jemis.catalog.ProductDto;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.common.ApiException;
import kz.jemis.common.I18n;
import kz.jemis.identity.AuthUser;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/customer/favorites")
public class FavoritesController {
    private final EntityManager em;
    private final ProductRepository products;

    public FavoritesController(EntityManager em, ProductRepository products) {
        this.em = em;
        this.products = products;
    }

    /** Favorites incl. inactive products (flagged unavailable) so the client can explain what happened. */
    @GetMapping
    @Transactional(readOnly = true)
    public List<ProductDto> list(@AuthenticationPrincipal AuthUser me) {
        String lang = I18n.lang();
        @SuppressWarnings("unchecked")
        List<UUID> ids = em.createNativeQuery("select product_id from favorites where user_id = :u order by created_at desc")
                .setParameter("u", me.id()).getResultList();
        return products.findAllById(ids).stream().map(p -> ProductDto.of(p, lang, false)).toList();
    }

    @PutMapping("/{productId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void add(@AuthenticationPrincipal AuthUser me, @PathVariable UUID productId) {
        Product p = products.findById(productId).filter(Product::isActive)
                .orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found"));
        em.createNativeQuery("insert into favorites(user_id, product_id) values (:u,:p) on conflict do nothing")
                .setParameter("u", me.id()).setParameter("p", p.getId()).executeUpdate();
    }

    @DeleteMapping("/{productId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void remove(@AuthenticationPrincipal AuthUser me, @PathVariable UUID productId) {
        em.createNativeQuery("delete from favorites where user_id = :u and product_id = :p")
                .setParameter("u", me.id()).setParameter("p", productId).executeUpdate();
    }
}
