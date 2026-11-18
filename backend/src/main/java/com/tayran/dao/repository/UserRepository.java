package com.tayran.dao.repository;

import com.tayran.dao.entity.User;
import com.tayran.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByPhoneAndRole(String phone, UserRole role);

    boolean existsByPhoneAndRole(String phone, UserRole role);

    boolean existsByRole(UserRole role);

    List<User> findByRoleOrderByIdAsc(UserRole role);

    Optional<User> findByIdAndRole(Long id, UserRole role);
}
