package kz.jemis.common;

import jakarta.persistence.EntityManager;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditService {
    private final EntityManager em;

    public AuditService(EntityManager em) { this.em = em; }

    @Transactional(propagation = Propagation.REQUIRED)
    public void record(UUID actorId, String action, String entity, Object entityId, String details) {
        String d = details != null && details.length() > 1000 ? details.substring(0, 1000) : details;
        em.createNativeQuery("insert into audit_log(actor_id, action, entity, entity_id, details) values (:a,:ac,:e,:i,:d)")
                .setParameter("a", actorId).setParameter("ac", action).setParameter("e", entity)
                .setParameter("i", entityId == null ? null : entityId.toString()).setParameter("d", d).executeUpdate();
    }
}
