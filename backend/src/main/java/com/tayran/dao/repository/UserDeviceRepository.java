package com.tayran.dao.repository;

import com.tayran.dao.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    Optional<UserDevice> findByFcmToken(String fcmToken);

    List<UserDevice> findByUserId(Long userId);

    @Modifying
    @Transactional
    @Query("DELETE FROM UserDevice d WHERE d.fcmToken = :token AND d.userId = :userId")
    int deleteByTokenAndUser(@Param("token") String token, @Param("userId") Long userId);

    /** Tokens FCM reported as invalid or unregistered. */
    @Modifying
    @Transactional
    @Query("DELETE FROM UserDevice d WHERE d.fcmToken IN :tokens")
    int deleteByTokens(@Param("tokens") Collection<String> tokens);
}
