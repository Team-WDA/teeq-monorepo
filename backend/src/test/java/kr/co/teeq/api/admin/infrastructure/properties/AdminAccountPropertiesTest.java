package kr.co.teeq.api.admin.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties.BootstrapAccount;
import org.junit.jupiter.api.Test;

class AdminAccountPropertiesTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validate_withBlankUsername_hasViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(new BootstrapAccount("", "password-value", "운영자"));

        assertThat(validator.validate(properties)).isNotEmpty();
    }

    @Test
    void validate_withBlankPassword_hasViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(new BootstrapAccount("operator", " ", "운영자"));

        assertThat(validator.validate(properties)).isNotEmpty();
    }

    @Test
    void validate_withBlankName_hasViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(new BootstrapAccount("operator", "password-value", ""));

        assertThat(validator.validate(properties)).isNotEmpty();
    }

    @Test
    void validate_withFilledAccount_hasNoViolation() {
        AdminAccountProperties properties =
            new AdminAccountProperties(new BootstrapAccount("operator", "password-value", "운영자"));

        assertThat(validator.validate(properties)).isEmpty();
    }

    @Test
    void bootstrapAccount_whenAbsent_isNull() {
        AdminAccountProperties properties = new AdminAccountProperties(null);

        assertThat(properties.bootstrapAccount()).isNull();
        assertThat(validator.validate(properties)).isEmpty();
    }

    @Test
    void toString_masksPassword() {
        BootstrapAccount account = new BootstrapAccount("operator", "secret-password-value", "운영자");

        assertThat(account.toString()).doesNotContain("secret-password-value").contains("operator");
    }

}
