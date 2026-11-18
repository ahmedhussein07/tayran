package com.tayran.config;

import com.tayran.config.properties.AdminProperties;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.UserRepository;
import com.tayran.exception.BusinessException;
import com.tayran.model.UserRole;
import com.tayran.utils.PasswordPolicy;
import com.tayran.utils.PhoneUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates the first admin on startup when none exists, from ADMIN_SEED_PHONE and
 * ADMIN_SEED_PASSWORD. Without them it logs a warning and does nothing. The values are never logged.
 */
@Slf4j
@Order(0)
@Component
@RequiredArgsConstructor
public class AdminSeeder implements ApplicationRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminProperties properties;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (userRepository.existsByRole(UserRole.ADMIN)) {
            return;
        }
        String rawPhone = properties.seedPhone();
        String password = properties.seedPassword();
        if (rawPhone == null || rawPhone.isBlank() || password == null || password.isBlank()) {
            log.warn("No admin user exists and ADMIN_SEED_PHONE / ADMIN_SEED_PASSWORD are not set: skipping the seed admin");
            return;
        }
        String phone;
        try {
            phone = PhoneUtils.normalize(rawPhone);
        } catch (BusinessException e) {
            log.warn("ADMIN_SEED_PHONE is not a valid Egyptian mobile number: skipping the seed admin");
            return;
        }
        if (!PasswordPolicy.isAcceptable(password)) {
            log.warn("ADMIN_SEED_PASSWORD is too weak (min {} characters, a letter and a digit): skipping the seed admin",
                    PasswordPolicy.MIN_LENGTH);
            return;
        }
        User admin = new User(phone, UserRole.ADMIN);
        admin.setFirstName("Admin");
        admin.setPasswordHash(passwordEncoder.encode(password));
        userRepository.save(admin);
        log.info("Seed admin created (id {})", admin.getId());
    }
}
