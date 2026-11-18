package com.tayran.dao.repository;

import com.tayran.dao.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {

    Optional<Product> findByIdAndDeletedAtIsNull(Long id);

    /** Soft-deleted products count too: they keep their subcategory for order history. */
    boolean existsBySubcategoryId(Long subcategoryId);

    /** Live (not deleted) products per category: [categoryId, count]. */
    @Query("""
            SELECT s.categoryId, COUNT(p) FROM Product p, Subcategory s
            WHERE s.id = p.subcategoryId AND p.deletedAt IS NULL GROUP BY s.categoryId
            """)
    List<Object[]> countLiveByCategory();

    /** Live products per subcategory of one category: [subcategoryId, count]. */
    @Query("""
            SELECT p.subcategoryId, COUNT(p) FROM Product p, Subcategory s
            WHERE s.id = p.subcategoryId AND s.categoryId = :categoryId AND p.deletedAt IS NULL GROUP BY p.subcategoryId
            """)
    List<Object[]> countLiveBySubcategory(@Param("categoryId") Long categoryId);

    @Query("SELECT COALESCE(MAX(p.sortOrder), 0) FROM Product p WHERE p.subcategoryId = :subcategoryId")
    int maxSortOrder(@Param("subcategoryId") Long subcategoryId);
}
