package kz.jemis.payment;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
public class PaymentProviders {
    private final List<PaymentProvider> all;

    public PaymentProviders(List<PaymentProvider> all) { this.all = all; }

    public Optional<PaymentProvider> get(String key) { return all.stream().filter(p -> p.key().equals(key)).findFirst(); }

    /** The provider used for online payments: the first enabled provider that is not cash-on-delivery. */
    public Optional<PaymentProvider> onlineDefault() {
        return all.stream().filter(p -> p.isEnabled() && !p.key().equals(CashProvider.KEY)).findFirst();
    }

    public List<PaymentProvider> all() { return all; }
}
