package kz.jemis.address;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "addresses")
@Getter @Setter @NoArgsConstructor
public class Address {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "user_id") private UUID userId;
    private String label;
    private String city;
    private String street;
    private String house;
    private String apartment;
    private String entrance;
    private String floor;
    private String intercom;
    @Column(name = "recipient_name") private String recipientName;
    @Column(name = "recipient_phone") private String recipientPhone;
    private String instructions;
    private BigDecimal latitude;
    private BigDecimal longitude;
    @Column(name = "is_default") private boolean isDefault;
    @Column(name = "deleted_at") private Instant deletedAt;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
