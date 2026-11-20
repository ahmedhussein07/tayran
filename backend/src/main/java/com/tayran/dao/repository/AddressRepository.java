package com.tayran.dao.repository;

import com.tayran.dao.entity.Address;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long> {

    boolean existsByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(Long userId);

    Optional<Address> findByUserIdAndDefaultAddressTrueAndDeletedAtIsNull(Long userId);

    @Query("SELECT a FROM Address a JOIN FETCH a.village JOIN FETCH a.street WHERE a.userId = :userId AND a.defaultAddress = true AND a.deletedAt IS NULL")
    Optional<Address> findDefaultWithLocation(@Param("userId") Long userId);

    /** The customer's saved addresses: default first, then newest. */
    @Query("SELECT a FROM Address a JOIN FETCH a.village JOIN FETCH a.street WHERE a.userId = :userId AND a.deletedAt IS NULL ORDER BY a.defaultAddress DESC, a.id DESC")
    java.util.List<Address> findLive(@Param("userId") Long userId);

    @Query("SELECT a FROM Address a JOIN FETCH a.village JOIN FETCH a.street WHERE a.id = :id AND a.userId = :userId AND a.deletedAt IS NULL")
    Optional<Address> findLive(@Param("id") Long id, @Param("userId") Long userId);

    long countByUserIdAndDeletedAtIsNull(Long userId);
}
