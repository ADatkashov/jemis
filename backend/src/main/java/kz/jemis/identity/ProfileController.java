package kz.jemis.identity;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import kz.jemis.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/customer")
public class ProfileController {
    public record ProfileDto(UUID id, String email, String phone, String fullName, String locale, Role role,
                             boolean notifyOrders, boolean notifyPromos) {
        static ProfileDto of(User u) {
            return new ProfileDto(u.getId(), u.getEmail(), u.getPhone(), u.getFullName(), u.getLocale(), u.getRole(),
                    u.isNotifyOrders(), u.isNotifyPromos());
        }
    }
    public record UpdateProfile(@NotBlank @Size(max = 120) String fullName,
                                @Pattern(regexp = "^\\+?[0-9\\s\\-()]{10,18}$") String phone,
                                @Pattern(regexp = "ru|kk|en") String locale,
                                Boolean notifyOrders, Boolean notifyPromos) {}
    public record ChangePassword(@NotBlank String currentPassword, @NotBlank @Size(min = 8, max = 72) String newPassword) {}

    private final UserRepository users;
    private final AuthService auth;

    public ProfileController(UserRepository users, AuthService auth) { this.users = users; this.auth = auth; }

    @GetMapping("/me")
    public ProfileDto me(@AuthenticationPrincipal AuthUser me) {
        return ProfileDto.of(users.findById(me.id()).orElseThrow());
    }

    @PutMapping("/me")
    @Transactional
    public ProfileDto update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody UpdateProfile r) {
        User u = users.findById(me.id()).orElseThrow();
        String phone = AuthService.normalizePhone(r.phone());
        if (phone != null && !phone.equals(u.getPhone()) && users.findByPhone(phone).isPresent()) {
            throw ApiException.conflict("PHONE_IN_USE", "Phone number is already in use");
        }
        u.setFullName(r.fullName().trim());
        if (phone != null) u.setPhone(phone);
        if (r.locale() != null) u.setLocale(r.locale());
        if (r.notifyOrders() != null) u.setNotifyOrders(r.notifyOrders());
        if (r.notifyPromos() != null) u.setNotifyPromos(r.notifyPromos());
        return ProfileDto.of(u);
    }

    @PostMapping("/me/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody ChangePassword r) {
        auth.changePassword(me.id(), r.currentPassword(), r.newPassword());
    }

    /**
     * Account deletion request: the account is locked immediately and sessions are revoked.
     * Operators erase personal data after the legal retention check (documented in docs/OPERATIONS.md).
     */
    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Transactional
    public void requestDeletion(@AuthenticationPrincipal AuthUser me) {
        User u = users.findById(me.id()).orElseThrow();
        u.setStatus("DELETION_REQUESTED");
        u.setDeletionRequestedAt(Instant.now());
        auth.revokeAll(me.id());
    }
}
