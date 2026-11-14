package com.tayran.service;

import com.tayran.dao.entity.User;
import com.tayran.model.NextStep;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class NextStepResolverTest {

    private final NextStepResolver resolver = new NextStepResolver();

    @Test
    void newUserGoesToName() {
        assertThat(resolver.resolve(user(null, null), false)).isEqualTo(NextStep.NAME);
    }

    @Test
    void userWithOnlyAFirstNameGoesToName() {
        assertThat(resolver.resolve(user("Ahmed", null), false)).isEqualTo(NextStep.NAME);
        assertThat(resolver.resolve(user("Ahmed", "  "), false)).isEqualTo(NextStep.NAME);
    }

    @Test
    void nameIsAskedBeforeAddressEvenIfAnAddressExists() {
        assertThat(resolver.resolve(user(null, null), true)).isEqualTo(NextStep.NAME);
    }

    @Test
    void namedUserWithoutAddressGoesToAddress() {
        assertThat(resolver.resolve(user("أحمد", "حسين"), false)).isEqualTo(NextStep.ADDRESS);
    }

    @Test
    void namedUserWithAddressGoesHome() {
        assertThat(resolver.resolve(user("أحمد", "حسين"), true)).isEqualTo(NextStep.HOME);
    }

    private static User user(String firstName, String lastName) {
        User user = new User("+201012345678");
        user.setFirstName(firstName);
        user.setLastName(lastName);
        return user;
    }
}
