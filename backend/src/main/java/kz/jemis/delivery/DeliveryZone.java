package kz.jemis.delivery;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "delivery_zones")
@Getter @Setter @NoArgsConstructor
public class DeliveryZone {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    private String name;
    private String city;
    @Column(name = "fee_minor") private long feeMinor;
    @Column(name = "min_order_minor") private long minOrderMinor;
    @Column(name = "free_delivery_threshold_minor") private Long freeDeliveryThresholdMinor;
    private boolean active = true;
}
