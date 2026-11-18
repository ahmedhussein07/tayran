package com.tayran.dao.repository;

import com.tayran.dao.entity.ImageRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface ImageRecordRepository extends JpaRepository<ImageRecord, String> {

    /** Images no category or product points at (soft-deleted products included) and untouched since {@code before}. */
    @Query(value = """
            SELECT * FROM images i
            WHERE i.last_referenced_at < :before
              AND NOT EXISTS (SELECT 1 FROM categories c WHERE c.image_hash = i.hash)
              AND NOT EXISTS (SELECT 1 FROM products p WHERE p.image_hash = i.hash)
            """, nativeQuery = true)
    List<ImageRecord> findUnreferencedSince(@Param("before") Instant before);

    @Modifying
    @Query("UPDATE ImageRecord i SET i.lastReferencedAt = :now WHERE i.hash = :hash")
    int touch(@Param("hash") String hash, @Param("now") Instant now);
}
