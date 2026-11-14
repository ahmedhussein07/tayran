package com.tayran.dao.repository;

import com.tayran.dao.entity.Address;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long> {

    boolean existsByUserIdAndDefaultAddressTrue(Long userId);

    Optional<Address> findByUserIdAndDefaultAddressTrue(Long userId);

    @Query("SELECT a FROM Address a JOIN FETCH a.village JOIN FETCH a.street WHERE a.userId = :userId AND a.defaultAddress = true")
    Optional<Address> findDefaultWithLocation(@Param("userId") Long userId);
}
