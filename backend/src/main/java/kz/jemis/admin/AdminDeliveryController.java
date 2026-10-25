package kz.jemis.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.AuditService;
import kz.jemis.courier.Courier;
import kz.jemis.courier.CourierRepository;
import kz.jemis.delivery.DeliveryZone;
import kz.jemis.delivery.DeliveryZoneRepository;
import kz.jemis.delivery.SlotTemplate;
import kz.jemis.delivery.SlotTemplateRepository;
import kz.jemis.identity.AuthUser;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/delivery")
public class AdminDeliveryController {
    public record ZoneBody(@NotBlank @Size(max = 80) String name, @NotBlank @Size(max = 80) String city,
                           @NotNull @Min(0) Long feeMinor, @Min(0) long minOrderMinor,
                           @Min(0) Long freeDeliveryThresholdMinor, boolean active) {}
    public record SlotBody(@NotNull LocalTime startTime, @NotNull LocalTime endTime, @Min(0) int capacity,
                           @NotBlank @Pattern(regexp = "^[1-7](,[1-7])*$") String daysOfWeek, @Min(0) long extraFeeMinor,
                           boolean active) {}
    public record CourierRow(UUID id, UUID userId, String displayName, String phone, boolean active, boolean trackingConsent) {}

    private final DeliveryZoneRepository zones;
    private final SlotTemplateRepository slots;
    private final CourierRepository couriers;
    private final AuditService audit;

    public AdminDeliveryController(DeliveryZoneRepository zones, SlotTemplateRepository slots, CourierRepository couriers, AuditService audit) {
        this.zones = zones;
        this.slots = slots;
        this.couriers = couriers;
        this.audit = audit;
    }

    @GetMapping("/zones")
    public List<DeliveryZone> zones() { return zones.findAll(); }

    @PostMapping("/zones")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public DeliveryZone createZone(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody ZoneBody b) {
        DeliveryZone z = apply(new DeliveryZone(), b);
        zones.saveAndFlush(z);
        audit.record(me.id(), "ZONE_CREATE", "zone", z.getId(), z.getCity());
        return z;
    }

    @PutMapping("/zones/{id}")
    @Transactional
    public DeliveryZone updateZone(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody ZoneBody b) {
        DeliveryZone z = zones.findById(id).orElseThrow(() -> ApiException.notFound("ZONE_NOT_FOUND", "Zone not found"));
        apply(z, b);
        zones.flush();
        audit.record(me.id(), "ZONE_UPDATE", "zone", id, z.getCity());
        return z;
    }

    @GetMapping("/slots")
    public List<SlotTemplate> slots() { return slots.findAll(); }

    @PostMapping("/slots")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public SlotTemplate createSlot(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody SlotBody b) {
        SlotTemplate t = apply(new SlotTemplate(), b);
        slots.save(t);
        audit.record(me.id(), "SLOT_CREATE", "slot", t.getId(), t.getStartTime() + "-" + t.getEndTime());
        return t;
    }

    @PutMapping("/slots/{id}")
    @Transactional
    public SlotTemplate updateSlot(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody SlotBody b) {
        SlotTemplate t = slots.findById(id).orElseThrow(() -> ApiException.notFound("SLOT_NOT_FOUND", "Slot not found"));
        apply(t, b);
        audit.record(me.id(), "SLOT_UPDATE", "slot", id, null);
        return t;
    }

    @GetMapping("/couriers")
    public List<CourierRow> couriers() {
        return couriers.findAll().stream().map((Courier c) -> new CourierRow(c.getId(), c.getUserId(), c.getDisplayName(),
                c.getPhone(), c.isActive(), c.isTrackingConsent())).toList();
    }

    private DeliveryZone apply(DeliveryZone z, ZoneBody b) {
        z.setName(b.name());
        z.setCity(b.city().trim());
        z.setFeeMinor(b.feeMinor());
        z.setMinOrderMinor(b.minOrderMinor());
        z.setFreeDeliveryThresholdMinor(b.freeDeliveryThresholdMinor());
        z.setActive(b.active());
        return z;
    }

    private SlotTemplate apply(SlotTemplate t, SlotBody b) {
        if (!b.endTime().isAfter(b.startTime())) throw ApiException.badRequest("INVALID_SLOT", "End time must be after start time");
        t.setStartTime(b.startTime());
        t.setEndTime(b.endTime());
        t.setCapacity(b.capacity());
        t.setDaysOfWeek(b.daysOfWeek());
        t.setExtraFeeMinor(b.extraFeeMinor());
        t.setActive(b.active());
        return t;
    }
}
