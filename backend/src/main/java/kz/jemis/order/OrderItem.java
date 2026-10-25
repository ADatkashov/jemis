package kz.jemis.order;

import jakarta.persistence.*;
import java.util.UUID;
import kz.jemis.catalog.Unit;
import kz.jemis.common.I18n;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Immutable snapshot of the product as sold; later catalog edits never change past orders. */
@Entity
@Table(name = "order_items")
@Getter @Setter @NoArgsConstructor
public class OrderItem {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "product_id") private UUID productId;
    private String sku;
    @Column(name = "name_ru") private String nameRu;
    @Column(name = "name_kk") private String nameKk;
    @Column(name = "name_en") private String nameEn;
    @Enumerated(EnumType.STRING) private Unit unit;
    @Column(name = "image_url") private String imageUrl;
    @Column(name = "unit_price_minor") private long unitPriceMinor;
    @Column(name = "quantity_milli") private long quantityMilli;
    @Column(name = "line_total_minor") private long lineTotalMinor;

    public String name(String lang) { return I18n.pick(lang, nameRu, nameKk, nameEn); }
}
