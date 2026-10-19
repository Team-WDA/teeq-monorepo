package kr.co.teeq.api.admin.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.List;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.Account;
import org.junit.jupiter.api.Test;

class AdminAccountPropertiesTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validate_withBlankUsername_hasViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(List.of(new Account("", "password-value", "운영자")));

        assertThat(validator.validate(properties)).isNotEmpty();
    }

    @Test
    void validate_withFilledAccount_hasNoViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(List.of(new Account("operator", "password-value", "운영자")));

        assertThat(validator.validate(properties)).isEmpty();
    }

    @Test
    void constructor_withNullAccounts_usesEmptyList() {
        assertThat(new AdminAccountProperties(null).accounts()).isEmpty();
    }

}
