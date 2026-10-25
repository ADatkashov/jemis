package kz.jemis.identity;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, UUID> {
    @Query("select u from User u where lower(u.email) = lower(:email)")
    Optional<User> findByEmail(@Param("email") String email);

    Optional<User> findByPhone(String phone);

    boolean existsByRole(Role role);

    List<User> findByRoleIn(List<Role> roles);

    @Query("""
            select u from User u where u.role = :role and (:q is null or lower(u.fullName) like :q
              or lower(coalesce(u.email,'')) like :q or coalesce(u.phone,'') like :q)
            """)
    Page<User> search(@Param("role") Role role, @Param("q") String q, Pageable pageable);
}
