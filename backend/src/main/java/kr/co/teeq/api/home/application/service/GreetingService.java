package kr.co.teeq.api.home.application.service;

import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.home.core.port.GreetingGenerationPort;
import kr.co.teeq.api.home.core.port.GreetingRequest;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.GreetingMessageRule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 홈 한마디를 돌려준다. 홈 진입마다 AI 서버에서 받고, 실패하거나 규칙에 어긋나면 말투별 기본 문구를 쓴다.
 * AI가 유효한 문구를 줬을 때만 마지막 인사 시각을 기록한다.
 * 클래스에 트랜잭션을 두지 않는다. AI 호출 중 DB 트랜잭션을 열지 않기 위해서이고, 기록은 {@link LastGreetedAtCommandService}가 맡는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GreetingService {

    private final GreetingGenerationPort greetingGenerationPort;
    private final LastGreetedAtCommandService lastGreetedAtCommandService;
    private final OnboardingAnswerService onboardingAnswerService;
    private final SettingConfigService settingConfigService;

    public String greet(Member member, AiCharacterResponse character, String personaId) {
        // 말투 답변이 없는 상태는 기본 문구로 숨기지 않고 전파해야 하므로 AI 호출 전에 먼저 읽는다
        GreetingSpeech speech = GreetingSpeech.from(onboardingAnswerService.getSpeechStyle(member));
        GreetingRequest request = new GreetingRequest(member.getId(), personaId, member.getNickname(),
            character.name(), member.getLastGreetedAt());
        try {
            String generated = greetingGenerationPort.generate(request);
            if (GreetingMessageRule.isValidMessage(generated)) {
                lastGreetedAtCommandService.record(member.getId());
                return generated;
            }
            log.warn("홈 한마디 AI 응답이 규칙에 맞지 않아 기본 문구를 사용합니다. memberId={}, 응답 길이={}",
                member.getId(), generated == null ? 0 : generated.length());
        } catch (CustomException exception) {
            if (exception.getErrorCode() != ErrorCode.AI_SERVER_UNAVAILABLE) {
                throw exception;
            }
            log.warn("홈 한마디 AI 생성에 실패해 기본 문구를 사용합니다. memberId={}", member.getId(), exception);
        }
        return defaultMessage(member, speech);
    }

    private String defaultMessage(Member member, GreetingSpeech speech) {
        return settingConfigService.getString(speech.defaultMessageKey())
            .replace(GreetingMessageRule.HONORIFIC_PLACEHOLDER, speech.honorific(member.getNickname()));
    }

}
