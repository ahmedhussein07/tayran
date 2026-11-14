package com.tayran.dao.repository;

import com.tayran.dao.entity.OtpChallenge;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpChallengeRepository extends JpaRepository<OtpChallenge, UUID> {

    /** Serializes OTP requests for one phone until the transaction ends, so limits can't be raced. */
    @Query(value = "SELECT count(*) FROM (SELECT pg_advisory_xact_lock(hashtext(:phone))) AS phone_lock", nativeQuery = true)
    long lockPhone(@Param("phone") String phone);

    Optional<OtpChallenge> findFirstByPhoneOrderByCreatedOnDesc(String phone);

    long countByPhoneAndCreatedOnAfter(String phone, Instant since);

    Optional<OtpChallenge> findFirstByPhoneAndCreatedOnAfterOrderByCreatedOnAsc(String phone, Instant since);

    @Modifying
    @Query("UPDATE OtpChallenge c SET c.supersededAt = :now WHERE c.phone = :phone AND c.consumedAt IS NULL AND c.supersededAt IS NULL")
    int supersedeOpenChallenges(@Param("phone") String phone, @Param("now") Instant now);

    /** Locks the row so parallel guesses can't exceed the attempt limit. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM OtpChallenge c WHERE c.id = :id")
    Optional<OtpChallenge> findByIdForUpdate(@Param("id") UUID id);
}
