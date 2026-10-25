package kz.jemis.delivery;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DeliveryZoneRepository extends JpaRepository<DeliveryZone, UUID> {
    @Query("select z from DeliveryZone z where z.active = true and lower(z.city) = lower(:city)")
    Optional<DeliveryZone> findActiveByCity(@Param("city") String city);

    List<DeliveryZone> findByActiveTrueOrderByName();
}
