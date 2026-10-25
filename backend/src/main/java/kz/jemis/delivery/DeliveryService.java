package kz.jemis.delivery;

import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.SettingsService;
import kz.jemis.order.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DeliveryService {
    public record SlotView(UUID templateId, LocalTime start, LocalTime end, int capacity, int remaining,
                           boolean available, long extraFeeMinor) {}
    public record DayView(LocalDate date, List<SlotView> slots) {}
    public record Availability(String timezone, boolean immediateEnabled, List<DayView> days) {}

    private final DeliveryZoneRepository zones;
    private final SlotTemplateRepository templates;
    private final OrderRepository orders;
    private final SettingsService settings;
    private final EntityManager em;
    private final Clock clock;
    private final ZoneId zone;

    public DeliveryService(DeliveryZoneRepository zones, SlotTemplateRepository templates, OrderRepository orders,
                           SettingsService settings, EntityManager em, Clock clock, ZoneId businessZone) {
        this.zones = zones;
        this.templates = templates;
        this.orders = orders;
        this.settings = settings;
        this.em = em;
        this.clock = clock;
        this.zone = businessZone;
    }

    public Optional<DeliveryZone> zoneForCity(String city) { return zones.findActiveByCity(city); }

    public Optional<DeliveryZone> defaultZone() { return zones.findByActiveTrueOrderByName().stream().findFirst(); }

    @Transactional(readOnly = true)
    public Availability availability() {
        ZonedDateTime now = ZonedDateTime.now(clock.withZone(zone));
        int days = (int) settings.getLong("delivery.days_ahead", 3);
        List<SlotTemplate> ts = templates.findByActiveTrueOrderByStartTime();
        List<DayView> out = new ArrayList<>();
        for (int i = 0; i < days; i++) {
            LocalDate d = now.toLocalDate().plusDays(i);
            List<SlotView> slots = new ArrayList<>();
            for (SlotTemplate t : ts) {
                if (!t.runsOn(d.getDayOfWeek())) continue;
                int booked = (int) orders.countBooked(t.getId(), d);
                int remaining = Math.max(0, t.getCapacity() - booked);
                slots.add(new SlotView(t.getId(), t.getStartTime(), t.getEndTime(), t.getCapacity(), remaining,
                        remaining > 0 && bookable(t, d, now), t.getExtraFeeMinor()));
            }
            out.add(new DayView(d, slots));
        }
        return new Availability(zone.getId(), settings.getBool("delivery.immediate_enabled", false), out);
    }

    /**
     * Validates the slot and serialises bookings for it (transaction-scoped advisory lock), so two
     * checkouts cannot both take the last place. Must be called inside the order transaction.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public SlotTemplate reserveSlot(UUID templateId, LocalDate date) {
        SlotTemplate t = templates.findById(templateId).filter(SlotTemplate::isActive)
                .orElseThrow(() -> ApiException.conflict("SLOT_UNAVAILABLE", "Delivery slot is not available"));
        ZonedDateTime now = ZonedDateTime.now(clock.withZone(zone));
        int days = (int) settings.getLong("delivery.days_ahead", 3);
        if (date.isBefore(now.toLocalDate()) || !date.isBefore(now.toLocalDate().plusDays(days))
                || !t.runsOn(date.getDayOfWeek()) || !bookable(t, date, now)) {
            throw ApiException.conflict("SLOT_UNAVAILABLE", "Delivery slot is not available");
        }
        em.createNativeQuery("select pg_advisory_xact_lock(hashtext(:k))")
                .setParameter("k", templateId + ":" + date).getSingleResult();
        if (orders.countBooked(templateId, date) >= t.getCapacity()) {
            throw ApiException.conflict("SLOT_FULL", "Delivery slot is full");
        }
        return t;
    }

    private boolean bookable(SlotTemplate t, LocalDate d, ZonedDateTime now) {
        long lead = settings.getLong("delivery.lead_minutes", 60);
        Instant start = d.atTime(t.getStartTime()).atZone(zone).toInstant();
        return !start.minusSeconds(lead * 60).isBefore(now.toInstant());
    }
}
