package kz.jemis.courier;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourierAssignmentRepository extends JpaRepository<CourierAssignment, UUID> {
    List<CourierAssignment> findByCourierIdAndStatusInOrderByCreatedAtDesc(UUID courierId, Collection<CourierAssignment.Status> statuses);

    Optional<CourierAssignment> findByIdAndCourierId(UUID id, UUID courierId);

    Optional<CourierAssignment> findByOrderIdAndStatusIn(UUID orderId, Collection<CourierAssignment.Status> statuses);
}
