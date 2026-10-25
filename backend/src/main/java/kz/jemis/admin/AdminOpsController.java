package kz.jemis.admin;

import jakarta.persistence.EntityManager;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kz.jemis.catalog.Banner;
import kz.jemis.catalog.BannerRepository;
import kz.jemis.common.ApiException;
import kz.jemis.common.AuditService;
import kz.jemis.common.PageResponse;
import kz.jemis.common.SettingsService;
import kz.jemis.courier.Courier;
import kz.jemis.courier.CourierRepository;
import kz.jemis.identity.AuthService;
import kz.jemis.identity.AuthUser;
import kz.jemis.identity.Role;
import kz.jemis.identity.User;
import kz.jemis.identity.UserRepository;
import kz.jemis.order.OrderDto;
import kz.jemis.order.OrderRepository;
import kz.jemis.promotion.Promotion;
import kz.jemis.promotion.PromotionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

/** Promotions, banners, customers (ADMIN+MANAGER); staff, settings and audit log are ADMIN only. */
@RestController
@RequestMapping("/api/v1/admin")
public class AdminOpsController {
    public record PromoBody(@NotBlank @Size(max = 40) @Pattern(regexp = "[A-Za-z0-9_-]+") String code,
                            @NotNull Promotion.Type type, @NotNull @Min(1) Long value, @Min(1) Long maxDiscountMinor,
                            @Min(0) long minOrderMinor, Instant startsAt, Instant endsAt, @Min(1) Integer usageLimit,
                            @Min(1) Integer perCustomerLimit, UUID categoryId, boolean stackable, boolean active) {}
    public record BannerBody(@NotBlank String titleRu, @NotBlank String titleKk, @NotBlank String titleEn,
                             String subtitleRu, String subtitleKk, String subtitleEn, @Size(max = 500) String imageUrl,
                             @Pattern(regexp = "^#[0-9A-Fa-f]{6}$") String color, @Size(max = 300) String link,
                             int sortOrder, boolean active, Instant startsAt, Instant endsAt) {}
    public record CustomerRow(UUID id, String fullName, String email, String phone, String status, Instant createdAt) {}
    public record CustomerDetail(CustomerRow customer, List<OrderDto.Summary> orders) {}
    public record StaffBody(@NotBlank @Email String email, @NotBlank @Size(max = 120) String fullName,
                            @NotBlank @Size(min = 10, max = 72) String password, @NotNull Role role,
                            @Pattern(regexp = "^\\+?[0-9\\s\\-()]{10,18}$") String phone) {}
    public record StaffRow(UUID id, String fullName, String email, Role role, String status) {}
    public record StaffStatus(@NotNull Boolean active) {}

    private final PromotionRepository promos;
    private final BannerRepository banners;
    private final UserRepository users;
    private final OrderRepository orders;
    private final CourierRepository couriers;
    private final SettingsService settings;
    private final AuditService audit;
    private final PasswordEncoder encoder;
    private final AuthService auth;
    private final EntityManager em;

    public AdminOpsController(PromotionRepository promos, BannerRepository banners, UserRepository users, OrderRepository orders,
                              CourierRepository couriers, SettingsService settings, AuditService audit, PasswordEncoder encoder,
                              AuthService auth, EntityManager em) {
        this.promos = promos;
        this.banners = banners;
        this.users = users;
        this.orders = orders;
        this.couriers = couriers;
        this.settings = settings;
        this.audit = audit;
        this.encoder = encoder;
        this.auth = auth;
        this.em = em;
    }

    // ---- promotions
    @GetMapping("/promotions")
    public List<Promotion> promotions() { return promos.findAll(); }

    @PostMapping("/promotions")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public Promotion createPromo(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody PromoBody b) {
        if (promos.findByCodeIgnoreCase(b.code()).isPresent()) throw ApiException.conflict("CODE_IN_USE", "Promo code already exists");
        Promotion p = applyPromo(new Promotion(), b);
        promos.save(p);
        audit.record(me.id(), "PROMO_CREATE", "promotion", p.getId(), p.getCode());
        return p;
    }

    @PutMapping("/promotions/{id}")
    @Transactional
    public Promotion updatePromo(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody PromoBody b) {
        Promotion p = promos.findById(id).orElseThrow(() -> ApiException.notFound("PROMO_NOT_FOUND", "Promotion not found"));
        applyPromo(p, b);
        audit.record(me.id(), "PROMO_UPDATE", "promotion", id, p.getCode());
        return p;
    }

    // ---- banners
    @GetMapping("/banners")
    public List<Banner> banners() { return banners.findAll(); }

    @PostMapping("/banners")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public Banner createBanner(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody BannerBody b) {
        Banner x = applyBanner(new Banner(), b);
        banners.save(x);
        audit.record(me.id(), "BANNER_CREATE", "banner", x.getId(), x.getTitleEn());
        return x;
    }

    @PutMapping("/banners/{id}")
    @Transactional
    public Banner updateBanner(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody BannerBody b) {
        Banner x = banners.findById(id).orElseThrow(() -> ApiException.notFound("BANNER_NOT_FOUND", "Banner not found"));
        applyBanner(x, b);
        audit.record(me.id(), "BANNER_UPDATE", "banner", id, null);
        return x;
    }

    @DeleteMapping("/banners/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void deleteBanner(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        banners.deleteById(id);
        audit.record(me.id(), "BANNER_DELETE", "banner", id, null);
    }

    // ---- customers
    @GetMapping("/customers")
    @Transactional(readOnly = true)
    public PageResponse<CustomerRow> customers(@RequestParam(required = false) String q, @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "25") int size) {
        String like = q == null || q.isBlank() ? null : "%" + q.trim().toLowerCase().replace("%", "") + "%";
        return PageResponse.of(users.search(Role.CUSTOMER, like, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100),
                org.springframework.data.domain.Sort.by("createdAt").descending())), AdminOpsController::row);
    }

    @GetMapping("/customers/{id}")
    @Transactional(readOnly = true)
    public CustomerDetail customer(@PathVariable UUID id) {
        User u = users.findById(id).filter(x -> x.getRole() == Role.CUSTOMER)
                .orElseThrow(() -> ApiException.notFound("CUSTOMER_NOT_FOUND", "Customer not found"));
        return new CustomerDetail(row(u), orders.findByUserIdOrderByCreatedAtDesc(id, PageRequest.of(0, 50)).map(OrderDto.Summary::of).getContent());
    }

    // ---- staff (ADMIN only)
    @GetMapping("/staff")
    @PreAuthorize("hasRole('ADMIN')")
    public List<StaffRow> staff() {
        return users.findByRoleIn(List.of(Role.ADMIN, Role.MANAGER, Role.COURIER)).stream()
                .map(u -> new StaffRow(u.getId(), u.getFullName(), u.getEmail(), u.getRole(), u.getStatus())).toList();
    }

    @PostMapping("/staff")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public StaffRow createStaff(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody StaffBody b) {
        if (b.role() == Role.CUSTOMER) throw ApiException.badRequest("INVALID_ROLE", "Staff role required");
        String phone = AuthService.normalizePhone(b.phone());
        if (users.findByEmail(b.email()).isPresent() || (phone != null && users.findByPhone(phone).isPresent())) {
            throw ApiException.conflict("ACCOUNT_EXISTS", "Account already exists");
        }
        User u = new User();
        u.setEmail(b.email().toLowerCase());
        u.setPhone(phone);
        u.setFullName(b.fullName());
        u.setPasswordHash(encoder.encode(b.password()));
        u.setRole(b.role());
        users.save(u);
        if (b.role() == Role.COURIER) {
            Courier c = new Courier();
            c.setUserId(u.getId());
            c.setDisplayName(b.fullName());
            c.setPhone(u.getPhone());
            couriers.save(c);
        }
        audit.record(me.id(), "STAFF_CREATE", "user", u.getId(), b.role().name());
        return new StaffRow(u.getId(), u.getFullName(), u.getEmail(), u.getRole(), u.getStatus());
    }

    @PutMapping("/staff/{id}/active")
    @PreAuthorize("hasRole('ADMIN')")
    @Transactional
    public StaffRow setStaffActive(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id, @Valid @RequestBody StaffStatus b) {
        if (me.id().equals(id)) throw ApiException.badRequest("CANNOT_DISABLE_SELF", "You cannot disable your own account");
        User u = users.findById(id).filter(x -> x.getRole() != Role.CUSTOMER)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "Staff account not found"));
        u.setStatus(b.active() ? "ACTIVE" : "DISABLED");
        if (!b.active()) auth.revokeAll(id);
        couriers.findByUserId(id).ifPresent(c -> c.setActive(b.active()));
        audit.record(me.id(), b.active() ? "STAFF_ENABLE" : "STAFF_DISABLE", "user", id, null);
        return new StaffRow(u.getId(), u.getFullName(), u.getEmail(), u.getRole(), u.getStatus());
    }

    // ---- settings & audit (ADMIN only)
    @GetMapping("/settings")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, String> settings() { return settings.all(); }

    @PutMapping("/settings")
    @PreAuthorize("hasRole('ADMIN')")
    @Transactional
    public Map<String, String> updateSettings(@AuthenticationPrincipal AuthUser me, @RequestBody Map<String, @Size(max = 200) String> values) {
        values.forEach((k, v) -> {
            if (v == null || v.isBlank()) throw ApiException.badRequest("INVALID_SETTING", "Empty value for " + k);
            settings.put(k, v.trim());
        });
        audit.record(me.id(), "SETTINGS_UPDATE", "settings", null, String.join(",", values.keySet()));
        return settings.all();
    }

    @GetMapping("/audit-log")
    @PreAuthorize("hasRole('ADMIN')")
    @Transactional(readOnly = true)
    public List<Map<String, Object>> auditLog(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "50") int size) {
        List<?> rows = em.createNativeQuery("select a.created_at, a.actor_id, u.email, a.action, a.entity, a.entity_id, a.details from audit_log a left join users u on u.id = a.actor_id order by a.created_at desc limit :n offset :o")
                .setParameter("n", Math.min(Math.max(size, 1), 200)).setParameter("o", Math.max(page, 0) * Math.min(Math.max(size, 1), 200)).getResultList();
        return rows.stream().map(r -> {
            Object[] a = (Object[]) r;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("createdAt", a[0].toString());
            m.put("actorId", a[1]);
            m.put("actorEmail", a[2]);
            m.put("action", a[3]);
            m.put("entity", a[4]);
            m.put("entityId", a[5]);
            m.put("details", a[6]);
            return m;
        }).toList();
    }

    private static CustomerRow row(User u) {
        return new CustomerRow(u.getId(), u.getFullName(), u.getEmail(), u.getPhone(), u.getStatus(), u.getCreatedAt());
    }

    private Promotion applyPromo(Promotion p, PromoBody b) {
        if (b.type() == Promotion.Type.PERCENT && b.value() > 100) throw ApiException.badRequest("INVALID_PERCENT", "Percent must be 1-100");
        if (b.startsAt() != null && b.endsAt() != null && !b.endsAt().isAfter(b.startsAt())) throw ApiException.badRequest("INVALID_PERIOD", "End must be after start");
        p.setCode(b.code().toUpperCase());
        p.setType(b.type());
        p.setValue(b.value());
        p.setMaxDiscountMinor(b.maxDiscountMinor());
        p.setMinOrderMinor(b.minOrderMinor());
        p.setStartsAt(b.startsAt());
        p.setEndsAt(b.endsAt());
        p.setUsageLimit(b.usageLimit());
        p.setPerCustomerLimit(b.perCustomerLimit());
        p.setCategoryId(b.categoryId());
        p.setStackable(b.stackable());
        p.setActive(b.active());
        return p;
    }

    private Banner applyBanner(Banner x, BannerBody b) {
        x.setTitleRu(b.titleRu());
        x.setTitleKk(b.titleKk());
        x.setTitleEn(b.titleEn());
        x.setSubtitleRu(b.subtitleRu());
        x.setSubtitleKk(b.subtitleKk());
        x.setSubtitleEn(b.subtitleEn());
        x.setImageUrl(b.imageUrl());
        x.setColor(b.color());
        x.setLink(b.link());
        x.setSortOrder(b.sortOrder());
        x.setActive(b.active());
        x.setStartsAt(b.startsAt());
        x.setEndsAt(b.endsAt());
        return x;
    }
}
