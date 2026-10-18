package kr.co.teeq.api.aicharacter.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class GenerateAiCharacterRequestTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void 답변이_없으면_위반이다() {
        Set<ConstraintViolation<GenerateAiCharacterRequest>> violations =
            validator.validate(new GenerateAiCharacterRequest(null));

        assertThat(violations).extracting(ConstraintViolation::getMessage)
            .containsExactly("온보딩 답변을 보내 주세요.");
    }

    @Test
    void 답변_목록이_있으면_이름_검증_없이_통과한다() {
        assertThat(validator.validate(new GenerateAiCharacterRequest(List.of()))).isEmpty();
    }

}
