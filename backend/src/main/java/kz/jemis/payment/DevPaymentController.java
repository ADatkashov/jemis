package kz.jemis.payment;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.identity.AuthUser;
import kz.jemis.order.OrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * DEVELOPMENT ONLY (jemis.payment.mock.enabled=true). Lets a developer finish a mock payment: it builds a
 * signed provider notification and feeds it through the very same verified webhook path.
 */
@RestController
@RequestMapping("/api/v1/dev/payments")
@ConditionalOnProperty(name = "jemis.payment.mock.enabled", havingValue = "true")
public class DevPaymentController {
    private static final Logger log = LoggerFactory.getLogger(DevPaymentController.class);
    private final PaymentRepository payments;
    private final OrderRepository orders;
    private final MockPaymentProvider mock;
    private final PaymentService service;
    private final ObjectMapper mapper;

    public DevPaymentController(PaymentRepository payments, OrderRepository orders, MockPaymentProvider mock,
                                PaymentService service, ObjectMapper mapper) {
        log.warn("MOCK PAYMENT SIMULATOR ENABLED - development only, never enable in production");
        this.payments = payments;
        this.orders = orders;
        this.mock = mock;
        this.service = service;
        this.mapper = mapper;
    }

    @PostMapping("/{paymentId}/simulate")
    public Map<String, String> simulate(@AuthenticationPrincipal AuthUser me, @PathVariable UUID paymentId,
                                        @RequestParam(defaultValue = "success") String outcome) throws Exception {
        Payment p = payments.findById(paymentId).filter(x -> mock.key().equals(x.getProvider()))
                .filter(x -> orders.findByIdAndUserId(x.getOrderId(), me.id()).isPresent())
                .orElseThrow(() -> ApiException.notFound("PAYMENT_NOT_FOUND", "Payment not found"));
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("eventId", "evt_" + UUID.randomUUID());
        event.put("providerRef", p.getProviderRef());
        event.put("type", "success".equals(outcome) ? "SUCCEEDED" : "FAILED");
        event.put("amountMinor", p.getAmountMinor());
        if (!"success".equals(outcome)) event.put("failureReason", "simulated failure");
        byte[] body = mapper.writeValueAsBytes(event);
        var result = service.handleWebhook(mock.key(), Map.of(MockPaymentProvider.SIGNATURE_HEADER, mock.sign(body)), body);
        return Map.of("result", result.name(), "note", "DEVELOPMENT ONLY - no real transaction took place");
    }
}
