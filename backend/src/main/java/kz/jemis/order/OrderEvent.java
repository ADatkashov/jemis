package kz.jemis.order;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "order_events")
@Getter @Setter @NoArgsConstructor
public class OrderEvent {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "order_id") private UUID orderId;
    @Enumerated(EnumType.STRING) private OrderStatus status;
    @Column(name = "actor_id") private UUID actorId;
    private String note;
    @Column(name = "created_at", insertable = false, updatable = false) private Instant createdAt;
}
