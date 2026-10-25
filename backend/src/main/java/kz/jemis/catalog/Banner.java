package kz.jemis.catalog;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "banners")
@Getter @Setter @NoArgsConstructor
public class Banner {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "title_ru") private String titleRu;
    @Column(name = "title_kk") private String titleKk;
    @Column(name = "title_en") private String titleEn;
    @Column(name = "subtitle_ru") private String subtitleRu;
    @Column(name = "subtitle_kk") private String subtitleKk;
    @Column(name = "subtitle_en") private String subtitleEn;
    @Column(name = "image_url") private String imageUrl;
    private String color;
    private String link;
    @Column(name = "sort_order") private int sortOrder;
    private boolean active = true;
    @Column(name = "starts_at") private Instant startsAt;
    @Column(name = "ends_at") private Instant endsAt;
}
