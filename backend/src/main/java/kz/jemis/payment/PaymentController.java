package kz.jemis.payment;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import jakarta.servlet.http.HttpServletRequest;
import kz.jemis.common.SettingsService;
import kz.jemis.identity.AuthUser;
import kz.jemis.order.PaymentMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {
    public record MethodDto(PaymentMethod method, String provider, boolean developmentOnly) {}

    private final PaymentService service;
    private final PaymentProviders providers;
    private final SettingsService settings;

    public PaymentController(PaymentService service, PaymentProviders providers, SettingsService settings) {
        this.service = service;
        this.providers = providers;
        this.settings = settings;
    }

    /** Only methods that are actually operational are listed. */
    @GetMapping("/methods")
    public List<MethodDto> methods() {
        var out = new java.util.ArrayList<MethodDto>();
        if (settings.getBool("payment.cash_enabled", true)) out.add(new MethodDto(PaymentMethod.CASH, CashProvider.KEY, false));
        providers.onlineDefault().ifPresent(p -> out.add(new MethodDto(PaymentMethod.ONLINE, p.key(), p.developmentOnly())));
        return out;
    }

    @PostMapping("/orders/{orderId}/initiate")
    public PaymentService.PaymentView initiate(@AuthenticationPrincipal AuthUser me, @PathVariable UUID orderId) {
        return service.initiate(me.id(), orderId);
    }

    /** Public endpoint: authenticity comes solely from the provider signature verified inside the service. */
    @PostMapping("/webhooks/{provider}")
    public Map<String, String> webhook(@PathVariable String provider, HttpServletRequest request, @RequestBody byte[] body)
            throws IOException {
        Map<String, String> headers = new HashMap<>();
        request.getHeaderNames().asIterator().forEachRemaining(n -> headers.put(n.toLowerCase(), request.getHeader(n)));
        return Map.of("result", service.handleWebhook(provider, headers, body).name());
    }
}
