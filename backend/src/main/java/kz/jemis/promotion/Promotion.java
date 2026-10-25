package kz.jemis.promotion;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "promotions")
@Getter @Setter @NoArgsConstructor
public class Promotion {
    public enum Type { PERCENT, FIXED }

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    private String code;
    @Enumerated(EnumType.STRING) private Type type;
    private long value;
    @Column(name = "max_discount_minor") private Long maxDiscountMinor;
    @Column(name = "min_order_minor") private long minOrderMinor;
    @Column(name = "starts_at") private Instant startsAt;
    @Column(name = "ends_at") private Instant endsAt;
    @Column(name = "usage_limit") private Integer usageLimit;
    @Column(name = "per_customer_limit") private Integer perCustomerLimit;
    @Column(name = "category_id") private UUID categoryId;
    private boolean stackable;
    @Column(name = "used_count") private int usedCount;
    private boolean active = true;
    @Column(name = "created_at", insertable = false, updatable = false) private Instant createdAt;
}
