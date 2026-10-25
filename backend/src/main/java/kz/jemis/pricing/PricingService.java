package kz.jemis.pricing;

import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import kz.jemis.cart.CartItem;
import kz.jemis.catalog.Product;
import kz.jemis.catalog.ProductRepository;
import kz.jemis.common.ApiException;
import kz.jemis.common.I18n;
import kz.jemis.common.Money;
import kz.jemis.common.SettingsService;
import kz.jemis.delivery.DeliveryService;
import kz.jemis.delivery.DeliveryZone;
import kz.jemis.promotion.PromoService;
import kz.jemis.promotion.Promotion;
import org.springframework.stereotype.Service;

/** Single source of truth for prices, discounts and fees. Clients never send totals that are trusted. */
@Service
public class PricingService {
    public record Request(String city, Long slotExtraFeeMinor, String promoCode, UUID userId) {}

    private final ProductRepository products;
    private final DeliveryService delivery;
    private final PromoService promos;
    private final SettingsService settings;
    private final Clock clock;

    public PricingService(ProductRepository products, DeliveryService delivery, PromoService promos,
                          SettingsService settings, Clock clock) {
        this.products = products;
        this.delivery = delivery;
        this.promos = promos;
        this.settings = settings;
        this.clock = clock;
    }

    /** Result carries the resolved promotion so checkout can redeem exactly what was priced. */
    public record Priced(Quote quote, Promotion promotion) {}

    public Priced price(List<CartItem> items, Request req, String lang, boolean lenientPromo) {
        Map<UUID, Product> byId = products.findAllById(items.stream().map(CartItem::getProductId).toList()).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));
        List<Quote.Line> lines = new ArrayList<>();
        List<String> issues = new ArrayList<>();
        List<PromoService.Line> promoLines = new ArrayList<>();
        long subtotal = 0;
        boolean unavailable = false;
        for (CartItem ci : items) {
            Product p = byId.get(ci.getProductId());
            if (p == null) continue;
            String issue = null;
            if (!p.isAvailable()) { issue = "UNAVAILABLE"; unavailable = true; }
            else if (ci.getQuantityMilli() > p.availableMilli()) { issue = "INSUFFICIENT_STOCK"; unavailable = true; }
            long lineTotal = Money.lineTotal(p.getPriceMinor(), ci.getQuantityMilli());
            subtotal += lineTotal;
            lines.add(new Quote.Line(p.getId(), p.getSku(), p.name(lang), p.getImageUrl(), p.getUnit(), p.isWeighted(),
                    p.getStepMilli(), p.getPriceMinor(), p.getOldPriceMinor(), ci.getQuantityMilli(), lineTotal,
                    p.isAvailable(), Math.max(0, p.availableMilli()), issue));
            promoLines.add(new PromoService.Line(p.getId(), p.getCategoryId(), p.isDiscounted(), lineTotal));
        }
        if (lines.isEmpty()) issues.add("EMPTY_CART");
        if (unavailable) issues.add("UNAVAILABLE_ITEMS");

        long discount = 0;
        String promoError = null;
        Promotion promotion = null;
        if (req.promoCode() != null && !req.promoCode().isBlank() && !lines.isEmpty()) {
            try {
                PromoService.Result r = promos.evaluate(req.promoCode(), req.userId(), promoLines, subtotal, clock.instant());
                discount = r.discountMinor();
                promotion = r.promo();
            } catch (ApiException e) {
                if (!lenientPromo) throw e;
                promoError = e.code();
            }
        }

        boolean estimated = false;
        Optional<DeliveryZone> zone;
        if (req.city() != null) {
            zone = delivery.zoneForCity(req.city());
            if (zone.isEmpty()) issues.add("ADDRESS_NOT_SERVICEABLE");
        } else {
            zone = delivery.defaultZone();
            estimated = true;
        }
        long afterDiscount = subtotal - discount;
        long fee = 0, minOrder = 0;
        Long freeThreshold = null;
        if (zone.isPresent()) {
            DeliveryZone z = zone.get();
            minOrder = z.getMinOrderMinor();
            freeThreshold = z.getFreeDeliveryThresholdMinor();
            fee = freeThreshold != null && afterDiscount >= freeThreshold ? 0 : z.getFeeMinor();
            if (!lines.isEmpty() && afterDiscount < minOrder) issues.add("MIN_ORDER_NOT_MET");
        }
        fee += req.slotExtraFeeMinor() == null ? 0 : req.slotExtraFeeMinor();
        long service = settings.getLong("fees.service_minor", 0);
        long total = afterDiscount + fee + service;
        return new Priced(new Quote(lines, subtotal, discount, promotion == null ? null : promotion.getCode(), promoError,
                fee, service, total, minOrder, freeThreshold, estimated, issues, "KZT"), promotion);
    }

    public Priced price(List<CartItem> items, Request req, boolean lenientPromo) {
        return price(items, req, I18n.lang(), lenientPromo);
    }
}
