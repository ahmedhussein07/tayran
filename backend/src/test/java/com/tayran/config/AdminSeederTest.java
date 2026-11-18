package com.tayran.config;

import com.tayran.config.properties.AdminProperties;
import com.tayran.dao.entity.User;
import com.tayran.dao.repository.UserRepository;
import com.tayran.model.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AdminSeederTest {

    // TEST-ONLY values.
    private static final String PHONE = "010 5555 1234";
    private static final String PASSWORD = "SeederTest12345";

    private UserRepository users;
    private PasswordEncoder encoder;

    @BeforeEach
    void setUp() {
        users = mock(UserRepository.class);
        encoder = mock(PasswordEncoder.class);
        when(encoder.encode(any())).thenReturn("{bcrypt}$2a$12$hashed");
    }

    @Test
    void createsTheFirstAdminFromTheEnvironment() {
        when(users.existsByRole(UserRole.ADMIN)).thenReturn(false);
        seeder(PHONE, PASSWORD).run(null);

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(users).save(saved.capture());
        assertThat(saved.getValue().getRole()).isEqualTo(UserRole.ADMIN);
        assertThat(saved.getValue().getPhone()).isEqualTo("+201055551234");
        assertThat(saved.getValue().getPasswordHash()).isEqualTo("{bcrypt}$2a$12$hashed").isNotEqualTo(PASSWORD);
        verify(encoder).encode(PASSWORD);
    }

    @Test
    void doesNothingOnceAnAdminExists() {
        when(users.existsByRole(UserRole.ADMIN)).thenReturn(true);
        seeder(PHONE, PASSWORD).run(null);
        verify(users, never()).save(any());
    }

    @Test
    void skipsWithoutTheEnvironmentVariables() {
        when(users.existsByRole(UserRole.ADMIN)).thenReturn(false);
        seeder(null, null).run(null);
        seeder("", "").run(null);
        seeder(PHONE, null).run(null);
        verify(users, never()).save(any());
    }

    @Test
    void skipsAnInvalidPhoneOrAWeakPassword() {
        when(users.existsByRole(UserRole.ADMIN)).thenReturn(false);
        seeder("12345", PASSWORD).run(null);
        seeder(PHONE, "short").run(null);
        seeder(PHONE, "onlyletterslong").run(null);
        verify(users, never()).save(any());
    }

    private AdminSeeder seeder(String phone, String password) {
        return new AdminSeeder(users, encoder, new AdminProperties(phone, password, List.of(), true, 5,
                Duration.ofMinutes(15), 20, Duration.ofMinutes(10)));
    }
}
