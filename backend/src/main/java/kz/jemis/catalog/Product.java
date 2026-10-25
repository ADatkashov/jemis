package kz.jemis.catalog;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import kz.jemis.common.I18n;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "products")
@Getter @Setter @NoArgsConstructor
public class Product {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "category_id") private UUID categoryId;
    private String sku;
    private String brand;
    @Column(name = "variant_group") private String variantGroup;
    @Column(name = "name_ru") private String nameRu;
    @Column(name = "name_kk") private String nameKk;
    @Column(name = "name_en") private String nameEn;
    @Column(name = "description_ru") private String descriptionRu;
    @Column(name = "description_kk") private String descriptionKk;
    @Column(name = "description_en") private String descriptionEn;
    @Column(name = "ingredients_ru") private String ingredientsRu;
    @Column(name = "ingredients_kk") private String ingredientsKk;
    @Column(name = "ingredients_en") private String ingredientsEn;
    @Column(name = "storage_ru") private String storageRu;
    @Column(name = "storage_kk") private String storageKk;
    @Column(name = "storage_en") private String storageEn;
    private String allergens;
    private String keywords;
    @JdbcTypeCode(SqlTypes.JSON) private Map<String, String> attributes;
    @Enumerated(EnumType.STRING) private Unit unit;
    private boolean weighted;
    @Column(name = "step_milli") private int stepMilli = 1000;
    @Column(name = "pack_label") private String packLabel;
    @Column(name = "price_minor") private long priceMinor;
    @Column(name = "old_price_minor") private Long oldPriceMinor;
    private String currency = "KZT";
    @Column(name = "image_url") private String imageUrl;
    @Column(name = "stock_milli") private long stockMilli;
    @Column(name = "reserved_milli") private long reservedMilli;
    @Column(name = "low_stock_milli") private long lowStockMilli = 5000;
    private int popularity;
    private boolean active = true;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;
    @Version private long version;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); if (attributes == null) attributes = Map.of(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }

    public long availableMilli() { return stockMilli - reservedMilli; }
    public boolean isAvailable() { return active && availableMilli() > 0; }
    public boolean isDiscounted() { return oldPriceMinor != null && oldPriceMinor > priceMinor; }
    public String name(String lang) { return I18n.pick(lang, nameRu, nameKk, nameEn); }
}
