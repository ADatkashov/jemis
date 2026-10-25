package kz.jemis.order;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import kz.jemis.catalog.Unit;
import kz.jemis.payment.PaymentStatus;

public record OrderDto(UUID id, String number, OrderStatus status, PaymentStatus paymentStatus,
                       PaymentMethod paymentMethod, AddressSnapshot address, String recipientName,
                       String recipientPhone, String instructions, boolean immediate, SlotSnapshot slot,
                       long subtotalMinor, long discountMinor, long deliveryFeeMinor, long serviceFeeMinor,
                       long totalMinor, String currency, String promoCode, List<ItemDto> items,
                       List<EventDto> timeline, boolean cancellable, Instant createdAt) {

    public record AddressSnapshot(String city, String street, String house, String apartment, String entrance,
                                  String floor, String intercom) {}
    public record SlotSnapshot(LocalDate date, LocalTime start, LocalTime end) {}
    public record ItemDto(UUID productId, String sku, String name, Unit unit, String imageUrl, long unitPriceMinor,
                          long quantityMilli, long lineTotalMinor) {}
    public record EventDto(OrderStatus status, String note, Instant at) {}

    public record Summary(UUID id, String number, OrderStatus status, PaymentStatus paymentStatus, long totalMinor,
                          String currency, int itemCount, SlotSnapshot slot, Instant createdAt) {
        public static Summary of(Order o) {
            return new Summary(o.getId(), o.getNumber(), o.getStatus(), o.getPaymentStatus(), o.getTotalMinor(),
                    o.getCurrency(), o.getItems().size(), OrderDto.slot(o), o.getCreatedAt());
        }
    }

    static SlotSnapshot slot(Order o) {
        return o.getSlotDate() == null ? null : new SlotSnapshot(o.getSlotDate(), o.getSlotStart(), o.getSlotEnd());
    }

    public static OrderDto of(Order o, List<OrderEvent> events, String lang, boolean cancellable) {
        return new OrderDto(o.getId(), o.getNumber(), o.getStatus(), o.getPaymentStatus(), o.getPaymentMethod(),
                new AddressSnapshot(o.getAddrCity(), o.getAddrStreet(), o.getAddrHouse(), o.getAddrApartment(),
                        o.getAddrEntrance(), o.getAddrFloor(), o.getAddrIntercom()),
                o.getRecipientName(), o.getRecipientPhone(), o.getInstructions(), o.isImmediate(), slot(o),
                o.getSubtotalMinor(), o.getDiscountMinor(), o.getDeliveryFeeMinor(), o.getServiceFeeMinor(),
                o.getTotalMinor(), o.getCurrency(), o.getPromoCode(),
                o.getItems().stream().map(i -> new ItemDto(i.getProductId(), i.getSku(), i.name(lang), i.getUnit(),
                        i.getImageUrl(), i.getUnitPriceMinor(), i.getQuantityMilli(), i.getLineTotalMinor())).toList(),
                events.stream().map(e -> new EventDto(e.getStatus(), e.getNote(), e.getCreatedAt())).toList(),
                cancellable, o.getCreatedAt());
    }
}
