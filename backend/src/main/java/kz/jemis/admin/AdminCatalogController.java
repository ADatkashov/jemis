package kz.jemis.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kz.jemis.catalog.*;
import kz.jemis.common.ApiException;
import kz.jemis.common.AuditService;
import kz.jemis.common.PageResponse;
import kz.jemis.identity.AuthUser;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminCatalogController {
    public record CategoryBody(UUID parentId, @NotBlank @Size(max = 80) @Pattern(regexp = "[a-z0-9-]+") String slug,
                               @NotBlank @Size(max = 120) String nameRu, @NotBlank @Size(max = 120) String nameKk,
                               @NotBlank @Size(max = 120) String nameEn, @Size(max = 40) String icon,
                               @Size(max = 500) String imageUrl, int sortOrder, boolean active) {}
    public record CategoryAdminDto(UUID id, UUID parentId, String slug, String nameRu, String nameKk, String nameEn,
                                   String icon, String imageUrl, int sortOrder, boolean active) {
        static CategoryAdminDto of(Category c) {
            return new CategoryAdminDto(c.getId(), c.getParentId(), c.getSlug(), c.getNameRu(), c.getNameKk(), c.getNameEn(),
                    c.getIcon(), c.getImageUrl(), c.getSortOrder(), c.isActive());
        }
    }

    public record ProductBody(@NotNull UUID categoryId, @NotBlank @Size(max = 40) String sku, @Size(max = 80) String brand,
                              @Size(max = 80) String variantGroup,
                              @NotBlank @Size(max = 200) String nameRu, @NotBlank @Size(max = 200) String nameKk,
                              @NotBlank @Size(max = 200) String nameEn,
                              String descriptionRu, String descriptionKk, String descriptionEn,
                              String ingredientsRu, String ingredientsKk, String ingredientsEn,
                              String storageRu, String storageKk, String storageEn,
                              @Size(max = 300) String allergens, @Size(max = 400) String keywords,
                              Map<String, String> attributes, @NotNull Unit unit, boolean weighted,
                              @Min(1) int stepMilli, @Size(max = 40) String packLabel,
                              @NotNull @Min(0) Long priceMinor, @Min(1) Long oldPriceMinor,
                              @Size(max = 500) String imageUrl, @Min(0) long lowStockMilli, boolean active) {}
    public record ProductAdminDto(UUID id, UUID categoryId, String sku, String brand, String variantGroup, String nameRu,
                                  String nameKk, String nameEn, String descriptionRu, String descriptionKk, String descriptionEn,
                                  String ingredientsRu, String ingredientsKk, String ingredientsEn, String storageRu,
                                  String storageKk, String storageEn, String allergens, String keywords,
                                  Map<String, String> attributes, Unit unit, boolean weighted, int stepMilli,
                                  String packLabel, long priceMinor, Long oldPriceMinor, String imageUrl, long stockMilli,
                                  long reservedMilli, long lowStockMilli, boolean active) {
        static ProductAdminDto of(Product p) {
            return new ProductAdminDto(p.getId(), p.getCategoryId(), p.getSku(), p.getBrand(), p.getVariantGroup(), p.getNameRu(),
                    p.getNameKk(), p.getNameEn(), p.getDescriptionRu(), p.getDescriptionKk(), p.getDescriptionEn(),
                    p.getIngredientsRu(), p.getIngredientsKk(), p.getIngredientsEn(), p.getStorageRu(), p.getStorageKk(),
                    p.getStorageEn(), p.getAllergens(), p.getKeywords(), p.getAttributes(), p.getUnit(), p.isWeighted(),
                    p.getStepMilli(), p.getPackLabel(), p.getPriceMinor(), p.getOldPriceMinor(), p.getImageUrl(),
                    p.getStockMilli(), p.getReservedMilli(), p.getLowStockMilli(), p.isActive());
        }
    }
    public record StockBody(@NotNull Long deltaMilli, @NotBlank @Size(max = 200) String reason) {}

    private final CategoryRepository categories;
    private final ProductRepository products;
    private final AuditService audit;
    private final jakarta.persistence.EntityManager em;

    public AdminCatalogController(CategoryRepository categories, ProductRepository products, AuditService audit,
                                  jakarta.persistence.EntityManager em) {
        this.categories = categories;
        this.products = products;
        this.audit = audit;
        this.em = em;
    }

    @GetMapping("/categories")
    public List<CategoryAdminDto> categories() {
        return categories.findAll(Sort.by("sortOrder", "nameRu")).stream().map(CategoryAdminDto::of).toList();
    }

    @PostMapping("/categories")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public CategoryAdminDto createCategory(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody CategoryBody b) {
        if (categories.existsBySlug(b.slug())) throw ApiException.conflict("SLUG_IN_USE", "Slug already exists");
        Category c = new Category();
        applyCategory(c, b);
        categories.save(c);
        audit.record(me.id(), "CATEGORY_CREATE", "category", c.getId(), c.getSlug());
        return CategoryAdminDto.of(c);
    }

    @PutMapping("/categories/{id}")
    @Transactional
    public CategoryAdminDto updateCategory(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody CategoryBody b) {
        Category c = categories.findById(id).orElseThrow(() -> ApiException.notFound("CATEGORY_NOT_FOUND", "Category not found"));
        if (!c.getSlug().equals(b.slug()) && categories.existsBySlug(b.slug())) throw ApiException.conflict("SLUG_IN_USE", "Slug already exists");
        if (id.equals(b.parentId())) throw ApiException.badRequest("INVALID_PARENT", "Category cannot be its own parent");
        applyCategory(c, b);
        audit.record(me.id(), "CATEGORY_UPDATE", "category", id, c.getSlug());
        return CategoryAdminDto.of(c);
    }

    @GetMapping("/products")
    @Transactional(readOnly = true)
    public PageResponse<ProductAdminDto> products(@RequestParam(required = false) String q,
                                                  @RequestParam(required = false) UUID categoryId,
                                                  @RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "25") int size) {
        var spec = (org.springframework.data.jpa.domain.Specification<Product>) (root, query, cb) -> {
            var preds = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            if (categoryId != null) preds.add(cb.equal(root.get("categoryId"), categoryId));
            if (q != null && !q.isBlank()) {
                String like = "%" + q.trim().toLowerCase().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
                preds.add(cb.or(cb.like(cb.lower(root.get("nameRu")), like, '\\'), cb.like(cb.lower(root.get("sku")), like, '\\'),
                        cb.like(cb.lower(cb.coalesce(root.get("brand"), "")), like, '\\')));
            }
            return cb.and(preds.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return PageResponse.of(products.findAll(spec, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100), Sort.by("nameRu"))),
                ProductAdminDto::of);
    }

    @GetMapping("/products/{id}")
    public ProductAdminDto product(@PathVariable UUID id) {
        return ProductAdminDto.of(products.findById(id).orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found")));
    }

    @PostMapping("/products")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public ProductAdminDto createProduct(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody ProductBody b) {
        if (products.existsBySku(b.sku())) throw ApiException.conflict("SKU_IN_USE", "SKU already exists");
        Product p = new Product();
        applyProduct(p, b);
        products.save(p);
        audit.record(me.id(), "PRODUCT_CREATE", "product", p.getId(), p.getSku());
        return ProductAdminDto.of(p);
    }

    @PutMapping("/products/{id}")
    @Transactional
    public ProductAdminDto updateProduct(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody ProductBody b) {
        Product p = products.findById(id).orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found"));
        if (!p.getSku().equals(b.sku()) && products.existsBySku(b.sku())) throw ApiException.conflict("SKU_IN_USE", "SKU already exists");
        long oldPrice = p.getPriceMinor();
        applyProduct(p, b);
        audit.record(me.id(), "PRODUCT_UPDATE", "product", id, oldPrice != p.getPriceMinor() ? "price " + oldPrice + "->" + p.getPriceMinor() : p.getSku());
        return ProductAdminDto.of(p);
    }

    /** Manual stock correction with a mandatory reason; the audit trail lives in stock_adjustments. */
    @PostMapping("/products/{id}/stock")
    @Transactional
    public ProductAdminDto adjustStock(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody StockBody b) {
        Product p = products.lockAllById(List.of(id)).stream().findFirst()
                .orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found"));
        long after = p.getStockMilli() + b.deltaMilli();
        if (after < p.getReservedMilli()) {
            throw ApiException.conflict("STOCK_BELOW_RESERVED", "Stock cannot drop below the quantity reserved by open orders");
        }
        p.setStockMilli(after);
        em.createNativeQuery("insert into stock_adjustments(product_id, delta_milli, stock_after, reason, actor_id) values (:p,:d,:a,:r,:u)")
                .setParameter("p", id).setParameter("d", b.deltaMilli()).setParameter("a", after)
                .setParameter("r", b.reason()).setParameter("u", me.id()).executeUpdate();
        audit.record(me.id(), "STOCK_ADJUST", "product", id, b.deltaMilli() + ": " + b.reason());
        return ProductAdminDto.of(p);
    }

    @GetMapping("/products/{id}/stock-history")
    @Transactional(readOnly = true)
    public List<Map<String, Object>> stockHistory(@PathVariable UUID id) {
        List<?> rows = em.createNativeQuery("select delta_milli, stock_after, reason, actor_id, created_at from stock_adjustments where product_id = :p order by created_at desc limit 100")
                .setParameter("p", id).getResultList();
        return rows.stream().map(r -> {
            Object[] a = (Object[]) r;
            return Map.<String, Object>of("deltaMilli", a[0], "stockAfter", a[1], "reason", a[2],
                    "actorId", a[3] == null ? "" : a[3], "createdAt", a[4].toString());
        }).toList();
    }

    private void applyCategory(Category c, CategoryBody b) {
        if (b.parentId() != null) categories.findById(b.parentId()).orElseThrow(() -> ApiException.badRequest("INVALID_PARENT", "Parent category not found"));
        c.setParentId(b.parentId());
        c.setSlug(b.slug());
        c.setNameRu(b.nameRu());
        c.setNameKk(b.nameKk());
        c.setNameEn(b.nameEn());
        c.setIcon(b.icon());
        c.setImageUrl(b.imageUrl());
        c.setSortOrder(b.sortOrder());
        c.setActive(b.active());
    }

    private void applyProduct(Product p, ProductBody b) {
        categories.findById(b.categoryId()).orElseThrow(() -> ApiException.badRequest("INVALID_CATEGORY", "Category not found"));
        if (b.oldPriceMinor() != null && b.oldPriceMinor() <= b.priceMinor()) {
            throw ApiException.badRequest("INVALID_OLD_PRICE", "Previous price must be higher than the current price");
        }
        if (b.weighted() && b.unit() != Unit.KG && b.unit() != Unit.G && b.unit() != Unit.L && b.unit() != Unit.ML) {
            throw ApiException.badRequest("INVALID_UNIT", "Weighted products must use a weight or volume unit");
        }
        p.setCategoryId(b.categoryId());
        p.setSku(b.sku());
        p.setBrand(b.brand());
        p.setVariantGroup(b.variantGroup());
        p.setNameRu(b.nameRu());
        p.setNameKk(b.nameKk());
        p.setNameEn(b.nameEn());
        p.setDescriptionRu(b.descriptionRu());
        p.setDescriptionKk(b.descriptionKk());
        p.setDescriptionEn(b.descriptionEn());
        p.setIngredientsRu(b.ingredientsRu());
        p.setIngredientsKk(b.ingredientsKk());
        p.setIngredientsEn(b.ingredientsEn());
        p.setStorageRu(b.storageRu());
        p.setStorageKk(b.storageKk());
        p.setStorageEn(b.storageEn());
        p.setAllergens(b.allergens());
        p.setKeywords(b.keywords());
        p.setAttributes(b.attributes() == null ? Map.of() : b.attributes());
        p.setUnit(b.unit());
        p.setWeighted(b.weighted());
        p.setStepMilli(b.stepMilli());
        p.setPackLabel(b.packLabel());
        p.setPriceMinor(b.priceMinor());
        p.setOldPriceMinor(b.oldPriceMinor());
        p.setImageUrl(b.imageUrl());
        p.setLowStockMilli(b.lowStockMilli());
        p.setActive(b.active());
    }
}
