package kr.co.teeq.api.aicharacter.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class RenameAiCharacterRequestTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @ParameterizedTest
    @ValueSource(strings = {"가나", "가나다라마바사아자차", "티큐"})
    void 한글_2자에서_10자_이름은_통과한다(String name) {
        assertThat(validator.validate(new RenameAiCharacterRequest(name))).isEmpty();
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "가", "가나다라마바사아자차카", "가 나", "가나!", "가_나", "Ab", "Mina2", "티큐1", "ㅌㅋ"})
    void 비었거나_길이나_문자_규칙을_어기면_위반이다(String name) {
        assertThat(validator.validate(new RenameAiCharacterRequest(name))).isNotEmpty();
    }

}
