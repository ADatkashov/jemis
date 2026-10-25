package kz.jemis.order;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<Order, UUID>, JpaSpecificationExecutor<Order> {
    Optional<Order> findByIdAndUserId(UUID id, UUID userId);

    Optional<Order> findByUserIdAndIdempotencyKey(UUID userId, String key);

    Page<Order> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    @Query("select count(o) from Order o where o.slotTemplateId = :t and o.slotDate = :d and o.status <> kz.jemis.order.OrderStatus.CANCELLED")
    long countBooked(@Param("t") UUID templateId, @Param("d") LocalDate date);

    @Query("select o.id from Order o where o.status = kz.jemis.order.OrderStatus.PENDING_PAYMENT and o.createdAt < :cutoff")
    List<UUID> findExpiredUnpaid(@Param("cutoff") Instant cutoff);

    @Query(value = """
            select oi.product_id from order_items oi join orders o on o.id = oi.order_id
            where o.user_id = :u and o.status <> 'CANCELLED' group by oi.product_id order by count(*) desc limit :n
            """, nativeQuery = true)
    List<UUID> frequentProductIds(@Param("u") UUID userId, @Param("n") int limit);
}
