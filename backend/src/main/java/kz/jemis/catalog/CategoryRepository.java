package kz.jemis.catalog;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
    List<Category> findByActiveTrueOrderBySortOrderAscNameRuAsc();
    List<Category> findByParentId(UUID parentId);
    boolean existsBySlug(String slug);
}
