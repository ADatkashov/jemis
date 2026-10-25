package kz.jemis.admin;

import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import kz.jemis.catalog.Product;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.order.OrderDto;
import kz.jemis.order.OrderRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/dashboard")
public class AdminDashboardController {
    /**
     * Metric semantics: ordersToday = orders created today (business time zone) that are not cancelled;
     * paidRevenueTodayMinor = sum of totals of orders whose payment SUCCEEDED today (cash orders count once
     * delivered and settled; unpaid, cancelled or refunded orders never count).
     */
    public record Dashboard(long ordersToday, long paidRevenueTodayMinor, String currency, long awaitingProcessing,
                            long inDelivery, long lowStockCount, List<LowStock> lowStock, List<OrderDto.Summary> recentOrders) {}
    public record LowStock(java.util.UUID id, String sku, String name, long availableMilli, long thresholdMilli) {}

    private final EntityManager em;
    private final OrderRepository orders;
    private final ProductRepository products;
    private final Clock clock;
    private final ZoneId zone;

    public AdminDashboardController(EntityManager em, OrderRepository orders, ProductRepository products, Clock clock, ZoneId businessZone) {
        this.em = em;
        this.orders = orders;
        this.products = products;
        this.clock = clock;
        this.zone = businessZone;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public Dashboard get() {
        var start = LocalDate.now(clock.withZone(zone)).atStartOfDay(zone).toInstant();
        long today = ((Number) em.createNativeQuery("select count(*) from orders where created_at >= :s and status <> 'CANCELLED'").setParameter("s", start).getSingleResult()).longValue();
        Number rev = (Number) em.createNativeQuery("select coalesce(sum(total_minor),0) from orders where paid_at >= :s and payment_status = 'SUCCEEDED'")
                .setParameter("s", start).getSingleResult();
        long awaiting = count("select count(*) from orders where status in ('CONFIRMED','ACCEPTED','PREPARING','READY_FOR_DELIVERY')");
        long inDelivery = count("select count(*) from orders where status in ('ASSIGNED_TO_COURIER','PICKED_UP','ON_THE_WAY')");
        List<LowStock> low = products.findLowStock().stream().limit(10)
                .map((Product p) -> new LowStock(p.getId(), p.getSku(), p.getNameRu(), p.availableMilli(), p.getLowStockMilli())).toList();
        var recent = orders.findAll(PageRequest.of(0, 10, org.springframework.data.domain.Sort.by("createdAt").descending()))
                .map(OrderDto.Summary::of).getContent();
        return new Dashboard(today, rev.longValue(), "KZT", awaiting, inDelivery, products.countLowStock(), low, recent);
    }

    private long count(String sql) {
        return ((Number) em.createNativeQuery(sql).getSingleResult()).longValue();
    }
}
