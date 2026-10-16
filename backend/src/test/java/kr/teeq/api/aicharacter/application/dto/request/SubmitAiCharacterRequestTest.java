package kr.teeq.api.aicharacter.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class SubmitAiCharacterRequestTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @ParameterizedTest
    @ValueSource(strings = {"가나", "가나다라마바사아자1", "Ab", "tq12"})
    void 한글_영문_숫자_2자에서_10자_이름은_통과한다(String name) {
        assertThat(validator.validate(new SubmitAiCharacterRequest(name, List.of()))).isEmpty();
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "가", "가나다라마바사아자12", "가 나", "가나!", "가_나"})
    void 비었거나_길이나_문자_규칙을_어기면_위반이다(String name) {
        assertThat(validator.validate(new SubmitAiCharacterRequest(name, List.of()))).isNotEmpty();
    }

    @Test
    void 답변이_없으면_위반이다() {
        assertThat(validator.validate(new SubmitAiCharacterRequest("티큐", null))).isNotEmpty();
    }

}
