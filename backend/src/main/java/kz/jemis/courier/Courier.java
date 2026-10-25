package kz.jemis.courier;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "couriers")
@Getter @Setter @NoArgsConstructor
public class Courier {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "user_id") private UUID userId;
    @Column(name = "display_name") private String displayName;
    private String phone;
    @Column(name = "photo_url") private String photoUrl;
    private boolean active = true;
    @Column(name = "tracking_consent") private boolean trackingConsent;
    @Column(name = "last_lat") private BigDecimal lastLat;
    @Column(name = "last_lng") private BigDecimal lastLng;
    @Column(name = "last_location_at") private Instant lastLocationAt;
}
