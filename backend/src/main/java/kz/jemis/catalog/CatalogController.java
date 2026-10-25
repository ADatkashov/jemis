package kz.jemis.catalog;

import java.util.List;
import java.util.UUID;
import kz.jemis.common.I18n;
import kz.jemis.common.PageResponse;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/catalog")
public class CatalogController {
    public record CategoryDto(UUID id, UUID parentId, String slug, String name, String icon, String imageUrl, int sortOrder) {}
    public record BannerDto(UUID id, String title, String subtitle, String imageUrl, String color, String link) {}
    public record ProductDetail(ProductDto product, List<ProductDto> related) {}
    public record HomeResponse(List<BannerDto> banners, List<CategoryDto> categories, List<ProductDto> popular,
                               List<ProductDto> fresh, List<ProductDto> discounted) {}

    private final CatalogService catalog;

    public CatalogController(CatalogService catalog) { this.catalog = catalog; }

    @GetMapping("/categories")
    public List<CategoryDto> categories() {
        String lang = I18n.lang();
        return catalog.categoryList().stream().map(c -> categoryDto(c, lang)).toList();
    }

    @GetMapping("/banners")
    public List<BannerDto> banners() {
        String lang = I18n.lang();
        return catalog.liveBanners().stream().map(b -> bannerDto(b, lang)).toList();
    }

    @GetMapping("/products")
    public PageResponse<ProductDto> products(@RequestParam(required = false) String q,
                                             @RequestParam(required = false) UUID categoryId,
                                             @RequestParam(required = false) Long minPrice,
                                             @RequestParam(required = false) Long maxPrice,
                                             @RequestParam(required = false) Boolean inStock,
                                             @RequestParam(required = false) Boolean discounted,
                                             @RequestParam(required = false) String sort,
                                             @RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "20") int size) {
        String lang = I18n.lang();
        var result = catalog.search(new CatalogService.Filter(q, categoryId, minPrice, maxPrice, inStock, discounted, sort),
                page, size, lang);
        return PageResponse.of(result, p -> ProductDto.of(p, lang, false));
    }

    @GetMapping("/products/{id}")
    public ProductDetail product(@PathVariable UUID id) {
        String lang = I18n.lang();
        Product p = catalog.get(id);
        return new ProductDetail(ProductDto.of(p, lang, true),
                catalog.related(p).stream().map(r -> ProductDto.of(r, lang, false)).toList());
    }

    /** Everything the home screen needs in one round trip. */
    @GetMapping("/home")
    public HomeResponse home() {
        String lang = I18n.lang();
        var popular = catalog.search(new CatalogService.Filter(null, null, null, null, true, null, "popularity"), 0, 10, lang);
        var fresh = catalog.search(new CatalogService.Filter(null, null, null, null, true, null, "newest"), 0, 10, lang);
        var disc = catalog.search(new CatalogService.Filter(null, null, null, null, true, true, "popularity"), 0, 10, lang);
        return new HomeResponse(catalog.liveBanners().stream().map(b -> bannerDto(b, lang)).toList(),
                catalog.categoryList().stream().filter(c -> c.getParentId() == null).map(c -> categoryDto(c, lang)).toList(),
                popular.map(p -> ProductDto.of(p, lang, false)).getContent(),
                fresh.map(p -> ProductDto.of(p, lang, false)).getContent(),
                disc.map(p -> ProductDto.of(p, lang, false)).getContent());
    }

    static CategoryDto categoryDto(Category c, String lang) {
        return new CategoryDto(c.getId(), c.getParentId(), c.getSlug(), c.name(lang), c.getIcon(), c.getImageUrl(), c.getSortOrder());
    }

    static BannerDto bannerDto(Banner b, String lang) {
        return new BannerDto(b.getId(), I18n.pick(lang, b.getTitleRu(), b.getTitleKk(), b.getTitleEn()),
                I18n.pick(lang, b.getSubtitleRu(), b.getSubtitleKk(), b.getSubtitleEn()), b.getImageUrl(), b.getColor(), b.getLink());
    }
}
