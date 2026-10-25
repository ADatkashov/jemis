package kz.jemis.courier;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeliveryIssueRepository extends JpaRepository<DeliveryIssue, UUID> {
    List<DeliveryIssue> findByOrderIdOrderByCreatedAtDesc(UUID orderId);
}
