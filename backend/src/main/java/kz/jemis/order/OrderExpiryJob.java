package kz.jemis.order;

import java.time.Clock;
import java.time.Duration;
import kz.jemis.common.SettingsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Cancels abandoned online orders so reserved stock and slot capacity return to the pool. */
@Component
public class OrderExpiryJob {
    private static final Logger log = LoggerFactory.getLogger(OrderExpiryJob.class);
    private final OrderRepository orders;
    private final OrderService service;
    private final SettingsService settings;
    private final Clock clock;

    public OrderExpiryJob(OrderRepository orders, OrderService service, SettingsService settings, Clock clock) {
        this.orders = orders;
        this.service = service;
        this.settings = settings;
        this.clock = clock;
    }

    @Scheduled(fixedDelay = 60_000, initialDelay = 60_000)
    public void expireUnpaid() {
        long ttl = settings.getLong("orders.unpaid_ttl_minutes", 20);
        var ids = orders.findExpiredUnpaid(clock.instant().minus(Duration.ofMinutes(ttl)));
        for (var id : ids) {
            try {
                service.cancelIfStillUnpaid(id);
                log.info("Expired unpaid order {}", id);
            } catch (RuntimeException e) {
                log.warn("Could not expire order {}: {}", id, e.getMessage());
            }
        }
    }
}
