package kz.jemis.catalog;

import jakarta.persistence.LockModeType;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository extends JpaRepository<Product, UUID>, JpaSpecificationExecutor<Product> {
    boolean existsBySku(String sku);

    List<Product> findByVariantGroupAndActiveTrue(String variantGroup);

    List<Product> findTop12ByCategoryIdAndActiveTrueAndIdNotOrderByPopularityDesc(UUID categoryId, UUID id);

    /** Row locks in id order (callers pass sorted ids) so concurrent checkouts cannot deadlock or oversell. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Product p where p.id in :ids order by p.id")
    List<Product> lockAllById(@Param("ids") Collection<UUID> ids);

    @Query("select p from Product p where p.active = true and p.stockMilli - p.reservedMilli <= p.lowStockMilli order by p.stockMilli - p.reservedMilli")
    List<Product> findLowStock();

    @Query("select count(p) from Product p where p.active = true and p.stockMilli - p.reservedMilli <= p.lowStockMilli")
    long countLowStock();

    Optional<Product> findBySku(String sku);
}
