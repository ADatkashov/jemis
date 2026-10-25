package kz.jemis.identity;

/** Delivery channel for password-reset tokens (email/SMS). No real provider is bundled. */
public interface ResetTokenSender {
    void send(User user, String token);
}
