package kz.jemis.common;

import jakarta.persistence.EntityManager;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Application settings stored in the database so operators can change them without a release. */
@Service
public class SettingsService {
    public static final Set<String> KEYS = Set.of("delivery.days_ahead", "delivery.lead_minutes",
            "delivery.immediate_enabled", "fees.service_minor", "orders.unpaid_ttl_minutes", "payment.cash_enabled");

    private final EntityManager em;

    public SettingsService(EntityManager em) { this.em = em; }

    @Transactional(readOnly = true)
    public String get(String key, String def) {
        List<?> r = em.createNativeQuery("select value from settings where key = :k").setParameter("k", key).getResultList();
        return r.isEmpty() ? def : (String) r.get(0);
    }

    public long getLong(String key, long def) {
        try { return Long.parseLong(get(key, String.valueOf(def))); } catch (NumberFormatException e) { return def; }
    }

    public boolean getBool(String key, boolean def) { return Boolean.parseBoolean(get(key, String.valueOf(def))); }

    @Transactional(readOnly = true)
    public Map<String, String> all() {
        Map<String, String> m = new LinkedHashMap<>();
        for (Object o : em.createNativeQuery("select key, value from settings order by key").getResultList()) {
            Object[] row = (Object[]) o;
            m.put((String) row[0], (String) row[1]);
        }
        return m;
    }

    @Transactional
    public void put(String key, String value) {
        if (!KEYS.contains(key)) throw ApiException.badRequest("UNKNOWN_SETTING", "Unknown setting " + key);
        em.createNativeQuery("insert into settings(key, value, updated_at) values (:k, :v, now()) "
                + "on conflict (key) do update set value = :v, updated_at = now()")
                .setParameter("k", key).setParameter("v", value).executeUpdate();
    }
}
