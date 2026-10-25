package kz.jemis.delivery;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/delivery")
public class DeliveryController {
    private final DeliveryService delivery;

    public DeliveryController(DeliveryService delivery) { this.delivery = delivery; }

    /** Slot availability generated from backend configuration, capacity and lead time (business time zone). */
    @GetMapping("/availability")
    public DeliveryService.Availability availability() { return delivery.availability(); }
}
