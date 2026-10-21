package kr.co.teeq.api.home.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.home.core.port.GreetingGenerationPort;
import kr.co.teeq.api.home.core.port.GreetingRequest;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class GreetingServiceTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();
    private static final String PERSONA_ID = "persona-1";
    private static final Instant LAST_GREETED_AT = Instant.parse("2026-10-20T15:00:00Z");
    private static final AiCharacterResponse CHARACTER =
        new AiCharacterResponse("티큐", CharacterType.CHARACTER_3, List.of("a", "b", "c"));
    private static final String CASUAL_DEFAULT = "{호칭},\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...";

    @Mock
    private Member member;
    @Mock
    private GreetingGenerationPort greetingGenerationPort;
    @Mock
    private LastGreetedAtCommandService lastGreetedAtCommandService;
    @Mock
    private OnboardingAnswerService onboardingAnswerService;
    @Mock
    private SettingConfigService settingConfigService;

    @InjectMocks
    private GreetingService greetingService;

    @Test
    void greet_AI_정상_응답이면_그_문구를_돌려주고_인사_시각을_기록한다() {
        givenMember(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any())).willReturn("소연아, 안녕");

        assertThat(greetingService.greet(member, CHARACTER, PERSONA_ID)).isEqualTo("소연아, 안녕");

        verify(lastGreetedAtCommandService).record(MEMBER_ID);
        verifyNoInteractions(settingConfigService);
    }

    @Test
    void greet_요청에_갱신_이전의_인사_시각과_persona를_담는다() {
        givenMember(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any())).willReturn("소연 님, 안녕하세요");

        greetingService.greet(member, CHARACTER, PERSONA_ID);

        assertThat(capturedRequest())
            .isEqualTo(new GreetingRequest(MEMBER_ID, PERSONA_ID, "소연", "티큐", LAST_GREETED_AT));
    }

    @Test
    void greet_처음_인사면_요청의_인사_시각은_null이다() {
        givenMember(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE, null);
        given(greetingGenerationPort.generate(any())).willReturn("소연 님, 안녕하세요");

        greetingService.greet(member, CHARACTER, PERSONA_ID);

        assertThat(capturedRequest().lastGreetedAt()).isNull();
    }

    @Test
    void greet_AI_서버_장애이면_default에_호칭을_치환하고_인사_시각을_기록하지_않는다() {
        givenMember(OnboardingOption.SPEECH_STYLE_AFFECTIONATE_CASUAL, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));
        given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL)).willReturn(CASUAL_DEFAULT);

        String result = greetingService.greet(member, CHARACTER, PERSONA_ID);

        assertThat(result).isEqualTo("소연아,\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...");
        verify(lastGreetedAtCommandService, never()).record(any());
    }

    @Test
    void greet_존댓말이면_존댓말_default에_님_호칭을_쓴다() {
        givenMember(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));
        given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_POLITE))
            .willReturn("{호칭}, 오늘 어떠셨어요?");

        assertThat(greetingService.greet(member, CHARACTER, PERSONA_ID)).isEqualTo("소연 님, 오늘 어떠셨어요?");
    }

    @Test
    void greet_AI_응답이_규칙에_어긋나면_default를_쓰고_인사_시각을_기록하지_않는다() {
        // 본문은 10자로 규칙 안이고 전체 길이만 201자라 저장 길이 200자 규칙만 따로 검증한다
        String tooLongWithLineBreaks = "가".repeat(10) + "\n".repeat(191);
        for (String invalid : List.of("", "가".repeat(46), tooLongWithLineBreaks)) {
            given(member.getId()).willReturn(MEMBER_ID);
            given(member.getNickname()).willReturn("민지");
            given(onboardingAnswerService.getSpeechStyle(member))
                .willReturn(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
            given(greetingGenerationPort.generate(any())).willReturn(invalid);
            given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL))
                .willReturn(CASUAL_DEFAULT);

            assertThat(greetingService.greet(member, CHARACTER, PERSONA_ID)).startsWith("민지야,");
        }
        verify(lastGreetedAtCommandService, never()).record(any());
    }

    @Test
    void greet_default에_호칭_자리가_없어도_그대로_돌려준다() {
        givenMember(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));
        given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL)).willReturn("안녕");

        assertThat(greetingService.greet(member, CHARACTER, PERSONA_ID)).isEqualTo("안녕");
    }

    @Test
    void greet_말투_답변이_없으면_IllegalStateException을_전파하고_AI를_호출하지_않는다() {
        given(onboardingAnswerService.getSpeechStyle(member)).willThrow(new IllegalStateException("없음"));

        assertThatThrownBy(() -> greetingService.greet(member, CHARACTER, PERSONA_ID))
            .isInstanceOf(IllegalStateException.class);

        verifyNoInteractions(greetingGenerationPort, lastGreetedAtCommandService);
    }

    @Test
    void greet_AI_서버_장애가_아닌_CustomException은_default로_흡수하지_않고_전파한다() {
        givenMember(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL, LAST_GREETED_AT);
        given(greetingGenerationPort.generate(any())).willThrow(new CustomException(ErrorCode.STATE_CONFLICT));

        assertThatThrownBy(() -> greetingService.greet(member, CHARACTER, PERSONA_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));

        verifyNoInteractions(lastGreetedAtCommandService, settingConfigService);
    }

    private void givenMember(OnboardingOption speechStyle, Instant lastGreetedAt) {
        given(member.getId()).willReturn(MEMBER_ID);
        given(member.getNickname()).willReturn("소연");
        given(member.getLastGreetedAt()).willReturn(lastGreetedAt);
        given(onboardingAnswerService.getSpeechStyle(member)).willReturn(speechStyle);
    }

    private GreetingRequest capturedRequest() {
        ArgumentCaptor<GreetingRequest> captor = ArgumentCaptor.forClass(GreetingRequest.class);
        verify(greetingGenerationPort).generate(captor.capture());
        return captor.getValue();
    }

}
