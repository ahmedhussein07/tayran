package com.tayran.utils;

import com.tayran.exception.BusinessException;
import com.tayran.model.TayranConst;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PhoneUtilsTest {

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "01012345678       | +201012345678",
            "01112345678       | +201112345678",
            "01212345678       | +201212345678",
            "01512345678       | +201512345678",
            "+201012345678     | +201012345678",
            "00201012345678    | +201012345678",
            "010 1234 5678     | +201012345678",
            "+20 10 1234 5678  | +201012345678",
            "0020 15 1234 5678 | +201512345678",
            "'  01012345678  ' | +201012345678",
            "٠١٠١٢٣٤٥٦٧٨       | +201012345678",
    })
    void normalizesValidEgyptianMobiles(String raw, String expected) {
        assertThat(PhoneUtils.normalize(raw)).isEqualTo(expected);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {
            "01312345678",      // 013 is not a mobile prefix
            "01412345678",
            "01612345678",
            "0101234567",       // too short
            "010123456789",     // too long
            "1012345678",       // no leading 0 or country code
            "+2001012345678",   // 0 after the country code
            "+201312345678",
            "+211012345678",    // another country
            "0201012345678",
            "02 2345 6789",     // landline
            "0101234567a",
            "010-1234-5678",    // only spaces are accepted as separators
            "   "
    })
    void rejectsEverythingElse(String raw) {
        assertThatThrownBy(() -> PhoneUtils.normalize(raw))
                .isInstanceOf(BusinessException.class)
                .hasMessage(TayranConst.INVALID_PHONE);
    }
}
