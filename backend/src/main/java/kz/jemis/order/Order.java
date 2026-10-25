package kz.jemis.order;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kz.jemis.payment.PaymentStatus;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "orders")
@Getter @Setter @NoArgsConstructor
public class Order {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    private String number;
    @Column(name = "user_id") private UUID userId;
    @Enumerated(EnumType.STRING) private OrderStatus status;
    @Enumerated(EnumType.STRING) @Column(name = "payment_status") private PaymentStatus paymentStatus;
    @Enumerated(EnumType.STRING) @Column(name = "payment_method") private PaymentMethod paymentMethod;
    @Column(name = "addr_city") private String addrCity;
    @Column(name = "addr_street") private String addrStreet;
    @Column(name = "addr_house") private String addrHouse;
    @Column(name = "addr_apartment") private String addrApartment;
    @Column(name = "addr_entrance") private String addrEntrance;
    @Column(name = "addr_floor") private String addrFloor;
    @Column(name = "addr_intercom") private String addrIntercom;
    @Column(name = "addr_latitude") private BigDecimal addrLatitude;
    @Column(name = "addr_longitude") private BigDecimal addrLongitude;
    @Column(name = "recipient_name") private String recipientName;
    @Column(name = "recipient_phone") private String recipientPhone;
    private String instructions;
    private boolean immediate;
    @Column(name = "slot_template_id") private UUID slotTemplateId;
    @Column(name = "slot_date") private LocalDate slotDate;
    @Column(name = "slot_start") private LocalTime slotStart;
    @Column(name = "slot_end") private LocalTime slotEnd;
    @Column(name = "subtotal_minor") private long subtotalMinor;
    @Column(name = "discount_minor") private long discountMinor;
    @Column(name = "delivery_fee_minor") private long deliveryFeeMinor;
    @Column(name = "service_fee_minor") private long serviceFeeMinor;
    @Column(name = "total_minor") private long totalMinor;
    private String currency = "KZT";
    @Column(name = "promo_code") private String promoCode;
    @Column(name = "idempotency_key") private String idempotencyKey;
    @Column(name = "courier_id") private UUID courierId;
    @Column(name = "stock_committed") private boolean stockCommitted;
    @Column(name = "paid_at") private Instant paidAt;
    @Column(name = "operator_notes") private String operatorNotes;
    @Column(name = "created_at", updatable = false) private Instant createdAt;
    @Column(name = "updated_at") private Instant updatedAt;
    @Version private long version;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private List<OrderItem> items = new ArrayList<>();

    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
