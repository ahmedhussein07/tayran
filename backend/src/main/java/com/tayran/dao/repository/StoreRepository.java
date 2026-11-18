package com.tayran.dao.repository;

import com.tayran.dao.entity.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StoreRepository extends JpaRepository<Store, Long> {

    List<Store> findByCatalogDirtyTrue();

    /** Held for the whole publish, so a concurrent "mark dirty" lands after it and is not lost. */
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM Store s WHERE s.id = :id")
    java.util.Optional<Store> findByIdForUpdate(@org.springframework.data.repository.query.Param("id") Long id);

    /** Any catalog change republishes every store (categories and products are shared between stores). */
    @Modifying
    @Query("UPDATE Store s SET s.catalogDirty = true")
    int markAllDirty();
}
