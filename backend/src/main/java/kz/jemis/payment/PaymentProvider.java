package kz.jemis.payment;

import java.util.Map;
import kz.jemis.order.Order;

/**
 * Boundary to a payment service provider. A real adapter (e.g. FreedomPay) must be implemented against
 * the provider's current API documentation and merchant credentials; none is bundled.
 */
public interface PaymentProvider {
    enum EventType { SUCCEEDED, FAILED, CANCELLED }

    record InitResult(String providerRef, String redirectUrl, String note) {}

    /** A provider notification that has passed signature verification. */
    record Event(String eventId, String providerRef, EventType type, long amountMinor, String failureReason) {}

    String key();

    boolean isEnabled();

    /** True for providers that must never be used with real money (mock). */
    boolean developmentOnly();

    InitResult initiate(Payment payment, Order order);

    /** @throws kz.jemis.common.ApiException 401 INVALID_SIGNATURE when verification fails. */
    Event verifyAndParse(Map<String, String> headers, byte[] body);

    /** Refunds a successful payment; implementations that cannot refund throw UnsupportedOperationException. */
    void refund(Payment payment);
}
