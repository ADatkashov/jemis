package kz.jemis.payment;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "payments")
@Getter @Setter @NoArgsConstructor
public class Payment {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "order_id") private UUID orderId;
    private String provider;
    @Enumerated(EnumType.STRING) private PaymentStatus status = PaymentStatus.PENDING;
    @Column(name = "amount_minor") private long amountMinor;
    private String currency = "KZT";
    @Column(name = "provider_ref") private String providerRef;
    @Column(name = "failure_reason") private String failureReason;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;
    @Version private long version;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
