package kz.jemis.identity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    private String email;
    private String phone;
    @Column(name = "password_hash") private String passwordHash;
    @Column(name = "full_name") private String fullName;
    @Enumerated(EnumType.STRING) private Role role;
    private String status = "ACTIVE";
    private String locale = "ru";
    @Column(name = "notify_orders") private boolean notifyOrders = true;
    @Column(name = "notify_promos") private boolean notifyPromos;
    @Column(name = "deletion_requested_at") private Instant deletionRequestedAt;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;
    @Version private long version;

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }

    public boolean isActive() { return "ACTIVE".equals(status); }
}
