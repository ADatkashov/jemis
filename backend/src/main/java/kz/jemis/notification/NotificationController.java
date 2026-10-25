package kz.jemis.notification;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import kz.jemis.common.ApiException;
import kz.jemis.common.PageResponse;
import kz.jemis.identity.AuthUser;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {
    public record NotificationDto(UUID id, String type, String title, String body, UUID orderId, boolean read, Instant createdAt) {
        static NotificationDto of(Notification n) {
            return new NotificationDto(n.getId(), n.getType(), n.getTitle(), n.getBody(), n.getOrderId(), n.getReadAt() != null, n.getCreatedAt());
        }
    }

    private final NotificationRepository repo;

    public NotificationController(NotificationRepository repo) { this.repo = repo; }

    @GetMapping
    @Transactional(readOnly = true)
    public PageResponse<NotificationDto> list(@AuthenticationPrincipal AuthUser me,
                                              @RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(repo.findByUserIdOrderByCreatedAtDesc(me.id(), PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 50))),
                NotificationDto::of);
    }

    @GetMapping("/unread-count")
    public Map<String, Long> unread(@AuthenticationPrincipal AuthUser me) {
        return Map.of("count", repo.countByUserIdAndReadAtIsNull(me.id()));
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void read(@AuthenticationPrincipal AuthUser me, @PathVariable UUID id) {
        Notification n = repo.findByIdAndUserId(id, me.id())
                .orElseThrow(() -> ApiException.notFound("NOTIFICATION_NOT_FOUND", "Notification not found"));
        if (n.getReadAt() == null) n.setReadAt(Instant.now());
    }

    @PostMapping("/read-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void readAll(@AuthenticationPrincipal AuthUser me) { repo.markAllRead(me.id()); }
}
