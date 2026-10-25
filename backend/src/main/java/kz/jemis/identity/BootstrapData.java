package kz.jemis.identity;

import kz.jemis.courier.Courier;
import kz.jemis.courier.CourierRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates the first admin from environment variables (only if no admin exists) and, when
 * {@code jemis.demo-data=true} (dev profile only), DEMO accounts. No default password exists in production.
 */
@Component
public class BootstrapData implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(BootstrapData.class);
    private final UserRepository users;
    private final CourierRepository couriers;
    private final PasswordEncoder encoder;
    private final String adminEmail;
    private final String adminPassword;
    private final boolean demo;

    public BootstrapData(UserRepository users, CourierRepository couriers, PasswordEncoder encoder,
                         @Value("${jemis.bootstrap-admin.email:}") String adminEmail,
                         @Value("${jemis.bootstrap-admin.password:}") String adminPassword,
                         @Value("${jemis.demo-data:false}") boolean demo) {
        this.users = users;
        this.couriers = couriers;
        this.encoder = encoder;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
        this.demo = demo;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!users.existsByRole(Role.ADMIN)) {
            if (!adminEmail.isBlank() && adminPassword.length() >= 8) {
                create(adminEmail, null, adminPassword, "Administrator", Role.ADMIN);
                log.info("Bootstrap administrator created: {}", adminEmail);
            } else {
                log.warn("No administrator exists. Set JEMIS_BOOTSTRAP_ADMIN_EMAIL and JEMIS_BOOTSTRAP_ADMIN_PASSWORD to create one.");
            }
        }
        if (demo) {
            log.warn("DEMO DATA ENABLED (development only): creating demo customer and courier accounts");
            if (users.findByEmail("customer@jemis.local").isEmpty()) {
                create("customer@jemis.local", "+77001234567", "Customer123!", "Demo Customer", Role.CUSTOMER);
            }
            if (users.findByEmail("courier@jemis.local").isEmpty()) {
                User cu = create("courier@jemis.local", "+77007654321", "Courier123!", "Demo Courier", Role.COURIER);
                Courier c = new Courier();
                c.setUserId(cu.getId());
                c.setDisplayName("Demo Courier");
                c.setPhone(cu.getPhone());
                couriers.save(c);
            }
        }
    }

    private User create(String email, String phone, String password, String name, Role role) {
        User u = new User();
        u.setEmail(email.toLowerCase());
        u.setPhone(phone);
        u.setFullName(name);
        u.setPasswordHash(encoder.encode(password));
        u.setRole(role);
        return users.save(u);
    }
}
