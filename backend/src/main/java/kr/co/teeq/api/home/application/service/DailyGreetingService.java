package kr.co.teeq.api.home.application.service;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.home.core.entity.DailyGreeting;
import kr.co.teeq.api.home.core.port.GreetingGenerationPort;
import kr.co.teeq.api.home.core.port.GreetingRequest;
import kr.co.teeq.api.home.core.repository.DailyGreetingRepository;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.GreetingMessageRule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

/**
 * 오늘의 한마디를 돌려준다. 하루 한 건을 저장해 두고, 없으면 AI 서버에서 만들며 실패하거나 규칙에 어긋나면 말투별 default를 쓴다.
 * 클래스에 트랜잭션을 두지 않는다. AI 호출 중 DB 트랜잭션을 열지 않기 위해서이고, 저장은 {@link DailyGreetingCommandService}가 맡는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DailyGreetingService {

    private final DailyGreetingRepository dailyGreetingRepository;
    private final DailyGreetingCommandService dailyGreetingCommandService;
    private final GreetingGenerationPort greetingGenerationPort;
    private final OnboardingAnswerService onboardingAnswerService;
    private final SettingConfigService settingConfigService;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    public String getOrCreate(UUID memberId, String nickname, AiCharacterResponse character) {
        // 하루는 KST 0시 기준이다
        LocalDate today = clock.instant().atZone(koreaZoneId).toLocalDate();
        return dailyGreetingRepository.findByMemberIdAndGreetingDateAndDeletedFalse(memberId, today)
            .map(DailyGreeting::getMessage)
            .orElseGet(() -> create(memberId, nickname, character, today));
    }

    private String create(UUID memberId, String nickname, AiCharacterResponse character, LocalDate today) {
        // 말투 답변이 없는 상태는 default로 숨기지 않고 전파해야 하므로 AI 실패 처리 밖에서 먼저 읽는다
        OnboardingOption speechStyle = onboardingAnswerService.getSpeechStyle(memberId);
        GreetingSpeech speech = GreetingSpeech.from(speechStyle);
        String message = generateOrDefault(memberId, nickname, character, speechStyle, speech);
        try {
            return dailyGreetingCommandService.save(memberId, today, message);
        } catch (DataIntegrityViolationException exception) {
            // 동시 첫 진입으로 다른 요청이 먼저 저장한 경우다. 이 클래스가 트랜잭션 밖이라 새 조회가 오염되지 않는다
            return dailyGreetingRepository.findByMemberIdAndGreetingDateAndDeletedFalse(memberId, today)
                .map(DailyGreeting::getMessage)
                .orElseThrow(() -> exception);
        }
    }

    private String generateOrDefault(UUID memberId, String nickname, AiCharacterResponse character,
        OnboardingOption speechStyle, GreetingSpeech speech) {
        GreetingRequest request = new GreetingRequest(memberId, nickname, character.name(),
            character.characterNumber(), character.personalityTags(), speechStyle.name());
        try {
            String generated = greetingGenerationPort.generate(request);
            if (GreetingMessageRule.isValidMessage(generated)) {
                return generated;
            }
            log.warn("오늘의 한마디 AI 응답이 규칙에 맞지 않아 기본 문구를 사용합니다. memberId={}, 응답 길이={}",
                memberId, generated == null ? 0 : generated.length());
        } catch (CustomException exception) {
            if (exception.getErrorCode() != ErrorCode.AI_SERVER_UNAVAILABLE) {
                throw exception;
            }
            log.warn("오늘의 한마디 AI 생성에 실패해 기본 문구를 사용합니다. memberId={}", memberId, exception);
        }
        return settingConfigService.getString(speech.defaultMessageKey())
            .replace(GreetingMessageRule.HONORIFIC_PLACEHOLDER, speech.honorific(nickname));
    }

}
