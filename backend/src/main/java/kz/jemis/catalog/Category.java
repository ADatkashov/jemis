package kz.jemis.catalog;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import kz.jemis.common.I18n;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "categories")
@Getter @Setter @NoArgsConstructor
public class Category {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "parent_id") private UUID parentId;
    private String slug;
    @Column(name = "name_ru") private String nameRu;
    @Column(name = "name_kk") private String nameKk;
    @Column(name = "name_en") private String nameEn;
    private String icon;
    @Column(name = "image_url") private String imageUrl;
    @Column(name = "sort_order") private int sortOrder;
    private boolean active = true;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }

    public String name(String lang) { return I18n.pick(lang, nameRu, nameKk, nameEn); }
}
