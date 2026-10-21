package kr.co.teeq.api.aicharacter.infrastructure.adapter;

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
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
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
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);
        adapter = new AiServerCharacterGenerationAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_persona_id와_캐릭터_유형과_태그_3개를_돌려준다() {
        UUID memberId = UUID.randomUUID();
        server.expect(requestTo(BASE_URL + "/characters"))
            .andExpect(method(HttpMethod.POST))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andExpect(jsonPath("$.memberId").value(memberId.toString()))
            .andExpect(jsonPath("$.user_id").doesNotExist())
            .andExpect(jsonPath("$.characterName").doesNotExist())
            .andExpect(jsonPath("$.answers[0].questionCode").value("RELATIONSHIP"))
            .andExpect(jsonPath("$.answers[0].optionCodes[0]").value("RELATIONSHIP_CLOSE_FRIEND"))
            .andRespond(withSuccess(
                "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
                MediaType.APPLICATION_JSON));

        GeneratedAiCharacter generated = adapter.generate(memberId, answers());

        assertThat(generated).isEqualTo(
            new GeneratedAiCharacter("persona-1", CharacterType.CHARACTER_3, List.of("a", "b", "c")));
        server.verify();
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":\" \",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":1,\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_6\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":3,\"personalityTags\":[\"a\",\"b\",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\",\"d\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\" \",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",1,\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",null,\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\\u0000\",\"c\"]}",
        "{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\"}"
    })
    void 응답이_계약에_맞지_않으면_AI_서버_오류로_바꾼다(String responseBody) {
        assertInvalidResponse(responseBody);
    }

    @Test
    void persona_id가_64자를_넘으면_AI_서버_오류로_바꾸고_64자는_허용한다() {
        assertInvalidResponse("{\"personaId\":\"" + "p".repeat(65)
            + "\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}");

        server.reset();
        server.expect(requestTo(BASE_URL + "/characters"))
            .andRespond(withSuccess("{\"personaId\":\"" + "p".repeat(64)
                + "\",\"characterType\":\"CHARACTER_3\",\"personalityTags\":[\"a\",\"b\",\"c\"]}",
                MediaType.APPLICATION_JSON));
        assertThat(adapter.generate(UUID.randomUUID(), answers()).personaId()).hasSize(64);
    }

    @Test
    void 태그가_50자를_넘으면_AI_서버_오류로_바꾸고_50자는_허용한다() {
        assertInvalidResponse("{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\","
            + "\"personalityTags\":[\"a\",\"b\",\"" + "c".repeat(51) + "\"]}");

        server.reset();
        server.expect(requestTo(BASE_URL + "/characters"))
            .andRespond(withSuccess("{\"personaId\":\"persona-1\",\"characterType\":\"CHARACTER_3\","
                + "\"personalityTags\":[\"a\",\"b\",\"" + "c".repeat(50) + "\"]}",
                MediaType.APPLICATION_JSON));
        assertThat(adapter.generate(UUID.randomUUID(), answers()).personalityTags()).hasSize(3);
    }

    private void assertInvalidResponse(String responseBody) {
        server.expect(requestTo(BASE_URL + "/characters"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> adapter.generate(UUID.randomUUID(), answers()))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    @Test
    void 서버_오류_응답이면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/characters")).andRespond(withServerError());

        assertThatThrownBy(() -> adapter.generate(UUID.randomUUID(), answers()))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    private Map<OnboardingQuestion, List<OnboardingOption>> answers() {
        Map<OnboardingQuestion, List<OnboardingOption>> answers = new EnumMap<>(OnboardingQuestion.class);
        answers.put(OnboardingQuestion.RELATIONSHIP, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND));
        return answers;
    }

}
