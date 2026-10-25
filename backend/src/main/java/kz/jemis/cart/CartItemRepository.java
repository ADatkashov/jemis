package kz.jemis.cart;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;

public interface CartItemRepository extends JpaRepository<CartItem, UUID> {
    List<CartItem> findByUserIdOrderByCreatedAt(UUID userId);

    Optional<CartItem> findByUserIdAndProductId(UUID userId, UUID productId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    void deleteByUserId(UUID userId);
}
