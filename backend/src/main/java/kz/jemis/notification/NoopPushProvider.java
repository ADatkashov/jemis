package kz.jemis.notification;

import kz.jemis.identity.User;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnMissingBean(value = PushProvider.class, ignored = NoopPushProvider.class)
public class NoopPushProvider implements PushProvider {
    @Override public boolean isConfigured() { return false; }
    @Override public boolean send(User user, String title, String body) { return false; }
}
