package kz.jemis.courier;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "delivery_issues")
@Getter @Setter @NoArgsConstructor
public class DeliveryIssue {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "order_id") private UUID orderId;
    @Column(name = "courier_id") private UUID courierId;
    private String description;
    @Column(name = "created_at", insertable = false, updatable = false) private Instant createdAt;
}
