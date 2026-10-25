package kz.jemis.catalog;

import jakarta.persistence.criteria.Predicate;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kz.jemis.common.ApiException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CatalogService {
    public record Filter(String q, UUID categoryId, Long minPriceMinor, Long maxPriceMinor, Boolean inStock,
                         Boolean discounted, String sort) {}

    private final ProductRepository products;
    private final CategoryRepository categories;
    private final BannerRepository banners;

    public CatalogService(ProductRepository products, CategoryRepository categories, BannerRepository banners) {
        this.products = products;
        this.categories = categories;
        this.banners = banners;
    }

    public List<Category> categoryList() { return categories.findByActiveTrueOrderBySortOrderAscNameRuAsc(); }

    public List<Banner> liveBanners() { return banners.findLive(Instant.now()); }

    public Page<Product> search(Filter f, int page, int size, String lang) {
        int s = Math.min(Math.max(size, 1), 60);
        Sort sort = switch (f.sort() == null ? "popularity" : f.sort()) {
            case "price_asc" -> Sort.by("priceMinor").ascending().and(Sort.by("id"));
            case "price_desc" -> Sort.by("priceMinor").descending().and(Sort.by("id"));
            case "name" -> Sort.by(switch (lang) { case "kk" -> "nameKk"; case "en" -> "nameEn"; default -> "nameRu"; })
                    .ascending().and(Sort.by("id"));
            case "newest" -> Sort.by("createdAt").descending().and(Sort.by("id"));
            case "popularity" -> Sort.by("popularity").descending().and(Sort.by("id"));
            default -> throw ApiException.badRequest("INVALID_SORT", "Unknown sort order");
        };
        Set<UUID> categoryIds = f.categoryId() == null ? null : withChildren(f.categoryId());
        return products.findAll(spec(f, categoryIds), PageRequest.of(Math.max(page, 0), s, sort));
    }

    public Product get(UUID id) {
        return products.findById(id).filter(Product::isActive)
                .orElseThrow(() -> ApiException.notFound("PRODUCT_NOT_FOUND", "Product not found"));
    }

    public List<Product> related(Product p) {
        List<Product> out = new ArrayList<>();
        if (p.getVariantGroup() != null) {
            products.findByVariantGroupAndActiveTrue(p.getVariantGroup()).stream()
                    .filter(x -> !x.getId().equals(p.getId())).forEach(out::add);
        }
        products.findTop12ByCategoryIdAndActiveTrueAndIdNotOrderByPopularityDesc(p.getCategoryId(), p.getId()).stream()
                .filter(x -> out.stream().noneMatch(o -> o.getId().equals(x.getId()))).limit(12).forEach(out::add);
        return out;
    }

    private Set<UUID> withChildren(UUID id) {
        Set<UUID> ids = new HashSet<>();
        ids.add(id);
        categories.findByParentId(id).forEach(c -> ids.add(c.getId()));
        return ids;
    }

    static Specification<Product> spec(Filter f, Set<UUID> categoryIds) {
        return (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            p.add(cb.isTrue(root.get("active")));
            if (categoryIds != null) p.add(root.get("categoryId").in(categoryIds));
            if (f.q() != null && !f.q().isBlank()) {
                String like = "%" + escape(f.q().trim().toLowerCase()) + "%";
                List<Predicate> any = new ArrayList<>();
                for (String field : List.of("nameRu", "nameKk", "nameEn", "brand", "keywords", "sku")) {
                    any.add(cb.like(cb.lower(cb.coalesce(root.<String>get(field), "")), like, '\\'));
                }
                p.add(cb.or(any.toArray(new Predicate[0])));
            }
            if (f.minPriceMinor() != null) p.add(cb.greaterThanOrEqualTo(root.get("priceMinor"), f.minPriceMinor()));
            if (f.maxPriceMinor() != null) p.add(cb.lessThanOrEqualTo(root.get("priceMinor"), f.maxPriceMinor()));
            if (Boolean.TRUE.equals(f.inStock())) {
                p.add(cb.greaterThan(cb.diff(root.<Long>get("stockMilli"), root.<Long>get("reservedMilli")), 0L));
            }
            if (Boolean.TRUE.equals(f.discounted())) {
                p.add(cb.isNotNull(root.get("oldPriceMinor")));
            }
            return cb.and(p.toArray(new Predicate[0]));
        };
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
