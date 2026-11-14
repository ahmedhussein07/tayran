package com.tayran.service;

import com.tayran.dao.entity.User;
import com.tayran.model.NextStep;
import org.springframework.stereotype.Component;

/** The single place that decides where the app goes next. */
@Component
public class NextStepResolver {

    public NextStep resolve(User user, boolean hasDefaultAddress) {
        if (isBlank(user.getFirstName()) || isBlank(user.getLastName())) {
            return NextStep.NAME;
        }
        if (!hasDefaultAddress) {
            return NextStep.ADDRESS;
        }
        return NextStep.HOME;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
