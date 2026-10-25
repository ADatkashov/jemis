package kz.jemis.payment;

import java.util.Map;
import kz.jemis.common.ApiException;
import kz.jemis.order.Order;
import org.springframework.stereotype.Component;

/** Cash/card on delivery: no online flow; the payment is settled by the courier at hand-over. */
@Component
public class CashProvider implements PaymentProvider {
    public static final String KEY = "cod";

    @Override public String key() { return KEY; }
    @Override public boolean isEnabled() { return true; }
    @Override public boolean developmentOnly() { return false; }

    @Override
    public InitResult initiate(Payment payment, Order order) { return new InitResult(null, null, null); }

    @Override
    public Event verifyAndParse(Map<String, String> headers, byte[] body) {
        throw ApiException.unauthorized("INVALID_SIGNATURE", "Invalid signature");
    }

    @Override public void refund(Payment payment) { /* cash is returned manually by an operator */ }
}
