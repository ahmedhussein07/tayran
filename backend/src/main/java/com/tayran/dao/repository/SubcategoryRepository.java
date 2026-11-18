package com.tayran.dao.repository;

import com.tayran.dao.entity.Subcategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubcategoryRepository extends JpaRepository<Subcategory, Long> {

    List<Subcategory> findByCategoryIdOrderBySortOrderAscIdAsc(Long categoryId);

    boolean existsByCategoryId(Long categoryId);

    @Query("SELECT COALESCE(MAX(s.sortOrder), 0) FROM Subcategory s WHERE s.categoryId = :categoryId")
    int maxSortOrder(@Param("categoryId") Long categoryId);
}
