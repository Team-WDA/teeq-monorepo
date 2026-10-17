package kr.teeq.api.home.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.home.core.entity.DailyGreeting;
import kr.teeq.api.home.core.port.GreetingGenerationPort;
import kr.teeq.api.home.core.port.GreetingRequest;
import kr.teeq.api.home.core.repository.DailyGreetingRepository;
import kr.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class DailyGreetingServiceTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();
    // UTC 15:30은 KST 다음 날 00:30이다
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-17T15:30:00Z"), ZoneOffset.UTC);
    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 18);
    private static final AiCharacterResponse CHARACTER = new AiCharacterResponse("티큐", 3, List.of("a", "b", "c"));
    private static final String CASUAL_DEFAULT = "{호칭},\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...";

    @Mock
    private DailyGreetingRepository dailyGreetingRepository;
    @Mock
    private DailyGreetingCommandService dailyGreetingCommandService;
    @Mock
    private GreetingGenerationPort greetingGenerationPort;
    @Mock
    private OnboardingAnswerService onboardingAnswerService;
    @Mock
    private SettingConfigService settingConfigService;

    private DailyGreetingService dailyGreetingService;

    @BeforeEach
    void setUp() {
        dailyGreetingService = new DailyGreetingService(dailyGreetingRepository, dailyGreetingCommandService,
            greetingGenerationPort, onboardingAnswerService, settingConfigService, CLOCK, KOREA_ZONE_ID);
    }

    @Test
    void getOrCreate_오늘_행이_있으면_AI와_저장을_호출하지_않는다() {
        given(dailyGreetingRepository.findByMemberIdAndGreetingDateAndDeletedFalse(MEMBER_ID, TODAY))
            .willReturn(Optional.of(DailyGreeting.of(MEMBER_ID, TODAY, "저장된 문구")));

        assertThat(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).isEqualTo("저장된 문구");

        verifyNoInteractions(greetingGenerationPort, dailyGreetingCommandService, onboardingAnswerService);
    }

    @Test
    void getOrCreate_AI_정상_응답이면_그_문구를_저장한다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
        given(greetingGenerationPort.generate(any())).willReturn("소연아, 안녕");
        givenSaveReturnsMessage();

        assertThat(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).isEqualTo("소연아, 안녕");

        verify(dailyGreetingCommandService).save(MEMBER_ID, TODAY, "소연아, 안녕");
        verifyNoInteractions(settingConfigService);
    }

    @Test
    void getOrCreate_GreetingRequest에_말투_선택지_이름을_담는다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE);
        given(greetingGenerationPort.generate(any())).willReturn("소연 님, 안녕하세요");
        givenSaveReturnsMessage();

        dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER);

        ArgumentCaptor<GreetingRequest> captor = ArgumentCaptor.forClass(GreetingRequest.class);
        verify(greetingGenerationPort).generate(captor.capture());
        assertThat(captor.getValue()).isEqualTo(new GreetingRequest(MEMBER_ID, "소연", "티큐", 3,
            List.of("a", "b", "c"), "SPEECH_STYLE_GENTLE_POLITE"));
    }

    @Test
    void getOrCreate_AI_서버_장애이면_default에_호칭을_치환해_저장한다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_AFFECTIONATE_CASUAL);
        given(greetingGenerationPort.generate(any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));
        given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL)).willReturn(CASUAL_DEFAULT);
        givenSaveReturnsMessage();

        String result = dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER);

        assertThat(result).isEqualTo("소연아,\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...");
        verify(dailyGreetingCommandService).save(MEMBER_ID, TODAY, result);
    }

    @Test
    void getOrCreate_AI_응답이_규칙에_어긋나면_default를_쓴다() {
        // 본문은 10자로 규칙 안이고 전체 길이만 201자라 저장 길이 200자 규칙만 따로 검증한다
        String tooLongWithLineBreaks = "가".repeat(10) + "\n".repeat(191);
        for (String invalid : List.of("", "가".repeat(46), tooLongWithLineBreaks)) {
            givenNoGreetingStored();
            givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
            given(greetingGenerationPort.generate(any())).willReturn(invalid);
            given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL))
                .willReturn(CASUAL_DEFAULT);
            givenSaveReturnsMessage();

            assertThat(dailyGreetingService.getOrCreate(MEMBER_ID, "민지", CHARACTER))
                .startsWith("민지야,");
        }
    }

    @Test
    void getOrCreate_default에_호칭_자리가_없어도_그대로_저장한다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
        given(greetingGenerationPort.generate(any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));
        given(settingConfigService.getString(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL)).willReturn("안녕");
        givenSaveReturnsMessage();

        assertThat(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).isEqualTo("안녕");
    }

    @Test
    void getOrCreate_저장이_unique_위반이면_저장된_행을_다시_읽어_돌려준다() {
        given(dailyGreetingRepository.findByMemberIdAndGreetingDateAndDeletedFalse(MEMBER_ID, TODAY))
            .willReturn(Optional.empty(), Optional.of(DailyGreeting.of(MEMBER_ID, TODAY, "먼저 저장된 문구")));
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
        given(greetingGenerationPort.generate(any())).willReturn("내 문구");
        willThrow(new DataIntegrityViolationException("unique"))
            .given(dailyGreetingCommandService).save(eq(MEMBER_ID), eq(TODAY), any());

        assertThat(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).isEqualTo("먼저 저장된 문구");
    }

    @Test
    void getOrCreate_unique_위반_후_재조회도_비면_원래_예외를_던진다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
        given(greetingGenerationPort.generate(any())).willReturn("내 문구");
        DataIntegrityViolationException violation = new DataIntegrityViolationException("unique");
        willThrow(violation).given(dailyGreetingCommandService).save(eq(MEMBER_ID), eq(TODAY), any());

        assertThatThrownBy(() -> dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER))
            .isSameAs(violation);
    }

    @Test
    void getOrCreate_말투_답변이_없으면_IllegalStateException을_전파하고_AI와_저장을_호출하지_않는다() {
        givenNoGreetingStored();
        given(onboardingAnswerService.getSpeechStyle(MEMBER_ID)).willThrow(new IllegalStateException("없음"));

        assertThatThrownBy(() -> dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER))
            .isInstanceOf(IllegalStateException.class);

        verifyNoInteractions(greetingGenerationPort, dailyGreetingCommandService);
    }

    @Test
    void getOrCreate_AI_서버_장애가_아닌_CustomException은_default로_흡수하지_않고_전파한다() {
        givenNoGreetingStored();
        givenSpeechStyle(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL);
        given(greetingGenerationPort.generate(any())).willThrow(new CustomException(ErrorCode.STATE_CONFLICT));

        assertThatThrownBy(() -> dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));

        verifyNoInteractions(dailyGreetingCommandService);
    }

    private void givenNoGreetingStored() {
        given(dailyGreetingRepository.findByMemberIdAndGreetingDateAndDeletedFalse(MEMBER_ID, TODAY))
            .willReturn(Optional.empty());
    }

    private void givenSpeechStyle(OnboardingOption speechStyle) {
        given(onboardingAnswerService.getSpeechStyle(MEMBER_ID)).willReturn(speechStyle);
    }

    private void givenSaveReturnsMessage() {
        given(dailyGreetingCommandService.save(eq(MEMBER_ID), eq(TODAY), any()))
            .willAnswer(invocation -> invocation.getArgument(2));
    }

}
