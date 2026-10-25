package kz.jemis.promotion;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PromotionRepository extends JpaRepository<Promotion, UUID> {
    Optional<Promotion> findByCodeIgnoreCase(String code);

    @Modifying
    @Query("update Promotion p set p.usedCount = p.usedCount + 1 where p.id = :id and (p.usageLimit is null or p.usedCount < p.usageLimit)")
    int tryConsume(@Param("id") UUID id);

    @Modifying
    @Query("update Promotion p set p.usedCount = p.usedCount - 1 where p.id = :id and p.usedCount > 0")
    int release(@Param("id") UUID id);
}
