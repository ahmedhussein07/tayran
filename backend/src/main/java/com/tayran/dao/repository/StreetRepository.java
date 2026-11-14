package com.tayran.dao.repository;

import com.tayran.dao.entity.Street;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StreetRepository extends JpaRepository<Street, Long> {

    List<Street> findByActiveTrueOrderBySortOrderAscIdAsc();

    Optional<Street> findByIdAndVillageIdAndActiveTrue(Long id, Long villageId);
}
