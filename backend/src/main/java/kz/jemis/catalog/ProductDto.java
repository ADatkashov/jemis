package kz.jemis.catalog;

import java.util.Map;
import java.util.UUID;
import kz.jemis.common.I18n;

public record ProductDto(UUID id, String sku, String name, String brand, UUID categoryId, String description,
                         String ingredients, String storage, String allergens, Map<String, String> attributes,
                         Unit unit, boolean weighted, int stepMilli, String packLabel, long priceMinor,
                         Long oldPriceMinor, Integer discountPercent, String currency, String imageUrl,
                         boolean available, long availableMilli, boolean lowStock) {

    public static ProductDto of(Product p, String lang, boolean detailed) {
        Integer pct = p.isDiscounted() ? (int) Math.round(100.0 * (p.getOldPriceMinor() - p.getPriceMinor()) / p.getOldPriceMinor()) : null;
        long avail = Math.max(0, p.availableMilli());
        return new ProductDto(p.getId(), p.getSku(), p.name(lang), p.getBrand(), p.getCategoryId(),
                detailed ? I18n.pick(lang, p.getDescriptionRu(), p.getDescriptionKk(), p.getDescriptionEn()) : null,
                detailed ? nullIfBlank(I18n.pick(lang, p.getIngredientsRu(), p.getIngredientsKk(), p.getIngredientsEn())) : null,
                detailed ? nullIfBlank(I18n.pick(lang, p.getStorageRu(), p.getStorageKk(), p.getStorageEn())) : null,
                detailed ? p.getAllergens() : null, detailed ? p.getAttributes() : null,
                p.getUnit(), p.isWeighted(), p.getStepMilli(), p.getPackLabel(), p.getPriceMinor(), p.getOldPriceMinor(),
                pct, p.getCurrency(), p.getImageUrl(), p.isAvailable(), avail,
                p.isAvailable() && p.availableMilli() <= p.getLowStockMilli());
    }

    private static String nullIfBlank(String s) { return s == null || s.isBlank() ? null : s; }
}
