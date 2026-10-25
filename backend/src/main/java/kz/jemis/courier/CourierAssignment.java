package kz.jemis.courier;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "courier_assignments")
@Getter @Setter @NoArgsConstructor
public class CourierAssignment {
    public enum Status { OFFERED, ACCEPTED, REJECTED, COMPLETED, CANCELLED }

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "order_id") private UUID orderId;
    @Column(name = "courier_id") private UUID courierId;
    @Enumerated(EnumType.STRING) private Status status = Status.OFFERED;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
