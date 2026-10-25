package kz.jemis.identity;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    public record RegisterRequest(@Email @Size(max = 254) String email,
                                  @Pattern(regexp = "^\\+?[0-9\\s\\-()]{10,18}$", message = "invalid phone") String phone,
                                  @NotBlank @Size(min = 8, max = 72) String password,
                                  @NotBlank @Size(max = 120) String fullName,
                                  @Pattern(regexp = "ru|kk|en") String locale) {}
    public record LoginRequest(@NotBlank String identifier, @NotBlank String password) {}
    public record RefreshRequest(@NotBlank String refreshToken) {}
    public record ResetRequest(@NotBlank String identifier) {}
    public record ResetConfirm(@NotBlank String token, @NotBlank @Size(min = 8, max = 72) String newPassword) {}

    private final AuthService auth;

    public AuthController(AuthService auth) { this.auth = auth; }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthService.Tokens register(@Valid @RequestBody RegisterRequest r) {
        User u = auth.register(r.email(), r.phone(), r.password(), r.fullName(), r.locale());
        return auth.issue(u);
    }

    @PostMapping("/login")
    public AuthService.Tokens login(@Valid @RequestBody LoginRequest r) { return auth.login(r.identifier(), r.password()); }

    @PostMapping("/refresh")
    public AuthService.Tokens refresh(@Valid @RequestBody RefreshRequest r) { return auth.refresh(r.refreshToken()); }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest r) { auth.logout(r.refreshToken()); }

    /** Always 202 so callers cannot tell whether the account exists. */
    @PostMapping("/password/reset-request")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void resetRequest(@Valid @RequestBody ResetRequest r) { auth.requestPasswordReset(r.identifier()); }

    @PostMapping("/password/reset-confirm")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetConfirm(@Valid @RequestBody ResetConfirm r) { auth.confirmPasswordReset(r.token(), r.newPassword()); }
}
