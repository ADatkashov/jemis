package kz.jemis.notification;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "notifications")
@Getter @Setter @NoArgsConstructor
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "user_id") private UUID userId;
    private String type;
    private String title;
    private String body;
    @Column(name = "order_id") private UUID orderId;
    @Column(name = "read_at") private Instant readAt;
    @Column(name = "push_state") private String pushState = "NOT_CONFIGURED";
    @Column(name = "push_attempts") private int pushAttempts;
    @Column(name = "created_at", insertable = false, updatable = false) private Instant createdAt;
}
