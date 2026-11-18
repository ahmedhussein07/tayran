package com.tayran.dao.repository;

import com.tayran.dao.entity.CatalogPublication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CatalogPublicationRepository extends JpaRepository<CatalogPublication, CatalogPublication.Key> {

    List<CatalogPublication> findByIdStoreIdAndDeletedAtIsNullAndPublishedAtBefore(Long storeId, Instant before);
}
