package kz.jemis.courier;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourierRepository extends JpaRepository<Courier, UUID> {
    Optional<Courier> findByUserId(UUID userId);

    List<Courier> findByActiveTrueOrderByDisplayName();
}
