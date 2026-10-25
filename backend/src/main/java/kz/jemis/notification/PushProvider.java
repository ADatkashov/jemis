package kz.jemis.notification;

import kz.jemis.identity.User;

/** Extension point for push delivery (e.g. Firebase Cloud Messaging). No provider is bundled or active. */
public interface PushProvider {
    boolean isConfigured();

    /** @return true when the provider accepted the message. */
    boolean send(User user, String title, String body);
}
