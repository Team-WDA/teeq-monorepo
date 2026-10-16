package kr.teeq.api.aicharacter.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AiServerCharacterGenerationAdapterTest {

    private static final String BASE_URL = "http://ai-server.test";
    private static final String HEADER_NAME = "X-Teeq-Server-Key";
    private static final String HEADER_VALUE = "dummy-server-key";

    private MockRestServiceServer server;
    private AiServerCharacterGenerationAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, 5000);
        adapter = new AiServerCharacterGenerationAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_캐릭터_번호와_태그_3개를_돌려준다() {
        UUID memberId = UUID.randomUUID();
        server.expect(requestTo(BASE_URL + "/characters"))
            .andExpect(method(HttpMethod.POST))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andExpect(jsonPath("$.user_id").value(memberId.toString()))
            .andExpect(jsonPath("$.character_name").value("티큐"))
            .andExpect(jsonPath("$.answers[0].question_code").value("RELATIONSHIP"))
            .andExpect(jsonPath("$.answers[0].option_codes[0]").value("RELATIONSHIP_CLOSE_FRIEND"))
            .andRespond(withSuccess("{\"character_number\":7,\"personality_tags\":[\"a\",\"b\",\"c\"]}",
                MediaType.APPLICATION_JSON));

        GeneratedAiCharacter generated = adapter.generate(memberId, "티큐", answers());

        assertThat(generated).isEqualTo(new GeneratedAiCharacter(7, List.of("a", "b", "c")));
        server.verify();
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"personality_tags\":[\"a\",\"b\",\"c\"]}",
        "{\"character_number\":7.5,\"personality_tags\":[\"a\",\"b\",\"c\"]}",
        "{\"character_number\":3000000000,\"personality_tags\":[\"a\",\"b\",\"c\"]}",
        "{\"character_number\":-1,\"personality_tags\":[\"a\",\"b\",\"c\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",\"b\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",\"b\",\"c\",\"d\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",\" \",\"c\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",1,\"c\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",null,\"c\"]}",
        "{\"character_number\":7,\"personality_tags\":[\"a\",\"b\\u0000\",\"c\"]}",
        "{\"character_number\":7}"
    })
    void 응답이_계약에_맞지_않으면_AI_서버_오류로_바꾼다(String responseBody) {
        assertInvalidResponse(responseBody);
    }

    @Test
    void 태그가_50자를_넘으면_AI_서버_오류로_바꾸고_50자는_허용한다() {
        assertInvalidResponse(
            "{\"character_number\":7,\"personality_tags\":[\"a\",\"b\",\"" + "c".repeat(51) + "\"]}");

        server.reset();
        server.expect(requestTo(BASE_URL + "/characters"))
            .andRespond(withSuccess(
                "{\"character_number\":7,\"personality_tags\":[\"a\",\"b\",\"" + "c".repeat(50) + "\"]}",
                MediaType.APPLICATION_JSON));
        assertThat(adapter.generate(UUID.randomUUID(), "티큐", answers()).personalityTags()).hasSize(3);
    }

    private void assertInvalidResponse(String responseBody) {
        server.expect(requestTo(BASE_URL + "/characters"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> adapter.generate(UUID.randomUUID(), "티큐", answers()))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    @Test
    void 서버_오류_응답이면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/characters")).andRespond(withServerError());

        assertThatThrownBy(() -> adapter.generate(UUID.randomUUID(), "티큐", answers()))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    private Map<OnboardingQuestion, List<OnboardingOption>> answers() {
        Map<OnboardingQuestion, List<OnboardingOption>> answers = new EnumMap<>(OnboardingQuestion.class);
        answers.put(OnboardingQuestion.RELATIONSHIP, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND));
        return answers;
    }

}
