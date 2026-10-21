package kr.co.teeq.api.auth.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class SignUpRequestValidationTest {

    private static final Validator VALIDATOR = Validation.buildDefaultValidatorFactory().getValidator();
    private static final String LONG_PASSWORD = "a1" + "b".repeat(63);

    private Set<ConstraintViolation<SignUpRequest>> validate(String email, String password, String nickname,
        boolean serviceTermsAgreed, boolean privacyPolicyAgreed) {
        return VALIDATOR.validate(
            new SignUpRequest(email, password, nickname, serviceTermsAgreed, privacyPolicyAgreed));
    }

    @Test
    void validRequest_hasNoViolations() {
        assertThat(validate("soyeon@teeq.com", "abcd1234!", "소연", true, true)).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {"abcdefgh", "12345678", "abc123", "abcd 1234", "비밀번호abcd1234"})
    void invalidPassword_isRejected(String password) {
        assertThat(validate("soyeon@teeq.com", password, "소연", true, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("password");
    }

    @Test
    void passwordLongerThan64Characters_isRejected() {
        assertThat(validate("soyeon@teeq.com", LONG_PASSWORD, "소연", true, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("password");
    }

    @ParameterizedTest
    @ValueSource(strings = {"a", "소", "열한글자를넘는닉네임입니다하", "abc", "티큐1", "ㅌㅋ", "소 연", "소연!", "소연😀"})
    void invalidNickname_isRejected(String nickname) {
        assertThat(validate("soyeon@teeq.com", "abcd1234", nickname, true, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("nickname");
    }

    @Test
    void missingRequiredTerms_isRejected() {
        assertThat(validate("soyeon@teeq.com", "abcd1234", "소연", false, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("serviceTermsAgreed");
        assertThat(validate("soyeon@teeq.com", "abcd1234", "소연", true, false))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("privacyPolicyAgreed");
    }

    @Test
    void invalidEmail_isRejected() {
        assertThat(validate("not-an-email", "abcd1234", "소연", true, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("email");
    }

    @Test
    void emailWithSurroundingWhitespace_isRejected() {
        assertThat(validate(" soyeon@teeq.com ", "abcd1234", "소연", true, true))
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly("email");
    }

}
