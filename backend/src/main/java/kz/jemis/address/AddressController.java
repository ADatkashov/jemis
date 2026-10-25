package kz.jemis.address;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.delivery.DeliveryZone;
import kz.jemis.delivery.DeliveryService;
import kz.jemis.identity.AuthUser;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/customer/addresses")
public class AddressController {
    public record AddressRequest(@Size(max = 60) String label, @NotBlank @Size(max = 80) String city,
                                 @NotBlank @Size(max = 160) String street, @NotBlank @Size(max = 20) String house,
                                 @Size(max = 20) String apartment, @Size(max = 20) String entrance,
                                 @Size(max = 20) String floor, @Size(max = 40) String intercom,
                                 @Size(max = 120) String recipientName,
                                 @Pattern(regexp = "^\\+?[0-9\\s\\-()]{10,18}$") String recipientPhone,
                                 @Size(max = 500) String instructions,
                                 @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
                                 @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude,
                                 Boolean isDefault) {}
    public record AddressDto(UUID id, String label, String city, String street, String house, String apartment,
                             String entrance, String floor, String intercom, String recipientName,
                             String recipientPhone, String instructions, BigDecimal latitude, BigDecimal longitude,
                             boolean isDefault) {
        static AddressDto of(Address a) {
            return new AddressDto(a.getId(), a.getLabel(), a.getCity(), a.getStreet(), a.getHouse(), a.getApartment(),
                    a.getEntrance(), a.getFloor(), a.getIntercom(), a.getRecipientName(), a.getRecipientPhone(),
                    a.getInstructions(), a.getLatitude(), a.getLongitude(), a.isDefault());
        }
    }
    public record Serviceability(boolean serviceable, String zone, Long feeMinor, Long minOrderMinor,
                                 Long freeDeliveryThresholdMinor) {}

    private final AddressRepository addresses;
    private final DeliveryService delivery;

    public AddressController(AddressRepository addresses, DeliveryService delivery) {
        this.addresses = addresses;
        this.delivery = delivery;
    }

    @GetMapping
    public List<AddressDto> list(@AuthenticationPrincipal AuthUser me) {
        return addresses.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(me.id()).stream().map(AddressDto::of).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public AddressDto create(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody AddressRequest r) {
        Address a = new Address();
        a.setUserId(me.id());
        apply(a, r);
        boolean first = addresses.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(me.id()).isEmpty();
        a.setDefault(first || Boolean.TRUE.equals(r.isDefault()));
        if (a.isDefault()) clearDefaults(me.id());
        return AddressDto.of(addresses.save(a));
    }

    @PutMapping("/{id}")
    @Transactional
    public AddressDto update(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody AddressRequest r) {
        Address a = owned(me, id);
        apply(a, r);
        if (Boolean.TRUE.equals(r.isDefault()) && !a.isDefault()) {
            clearDefaults(me.id());
            a.setDefault(true);
        }
        return AddressDto.of(a);
    }

    @PostMapping("/{id}/default")
    @Transactional
    public AddressDto makeDefault(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        Address a = owned(me, id);
        clearDefaults(me.id());
        a.setDefault(true);
        return AddressDto.of(a);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void delete(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        Address a = owned(me, id);
        boolean wasDefault = a.isDefault();
        addresses.delete(a);
        addresses.flush();
        if (wasDefault) {
            addresses.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(me.id()).stream().findFirst()
                    .ifPresent(n -> n.setDefault(true));
        }
    }

    @GetMapping("/{id}/serviceability")
    public Serviceability serviceability(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        Address a = owned(me, id);
        return delivery.zoneForCity(a.getCity())
                .map(z -> new Serviceability(true, z.getName(), z.getFeeMinor(), z.getMinOrderMinor(), z.getFreeDeliveryThresholdMinor()))
                .orElse(new Serviceability(false, null, null, null, null));
    }

    private Address owned(AuthUser me, UUID id) {
        // 404 (not 403) so identifiers of other customers' addresses are not disclosed.
        return addresses.findByIdAndUserIdAndDeletedAtIsNull(id, me.id())
                .orElseThrow(() -> ApiException.notFound("ADDRESS_NOT_FOUND", "Address not found"));
    }

    private void clearDefaults(UUID userId) {
        addresses.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId).forEach(x -> x.setDefault(false));
        addresses.flush();
    }

    private void apply(Address a, AddressRequest r) {
        a.setLabel(r.label());
        a.setCity(r.city().trim());
        a.setStreet(r.street().trim());
        a.setHouse(r.house().trim());
        a.setApartment(r.apartment());
        a.setEntrance(r.entrance());
        a.setFloor(r.floor());
        a.setIntercom(r.intercom());
        a.setRecipientName(r.recipientName());
        a.setRecipientPhone(r.recipientPhone());
        a.setInstructions(r.instructions());
        a.setLatitude(r.latitude());
        a.setLongitude(r.longitude());
    }
}
