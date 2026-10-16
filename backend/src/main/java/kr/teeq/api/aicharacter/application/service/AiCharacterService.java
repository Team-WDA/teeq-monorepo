package kr.teeq.api.aicharacter.application.service;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.teeq.api.aicharacter.application.dto.request.SubmitAiCharacterRequest;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * AI 캐릭터 제출과 조회. 제출은 답변 검증 -> AI 서버 호출 -> 저장 순서이며, AI 서버 호출 중에는 DB 트랜잭션을 열지 않는다.
 */
@Service
@RequiredArgsConstructor
public class AiCharacterService {

    private final OnboardingAnswerService onboardingAnswerService;
    private final AiCharacterGenerationPort aiCharacterGenerationPort;
    private final AiCharacterCommandService aiCharacterCommandService;
    private final AiCharacterRepository aiCharacterRepository;

    public AiCharacterSubmitResult submit(UUID memberId, SubmitAiCharacterRequest request) {
        onboardingAnswerService.validateAnswers(memberId, request.answers());
        GeneratedAiCharacter generated = aiCharacterGenerationPort.generate(
            memberId, request.name(), toAnswersByQuestion(request.answers()));
        return aiCharacterCommandService.save(memberId, request.name(), generated, request.answers());
    }

    @Transactional(readOnly = true)
    public AiCharacterResponse get(UUID memberId) {
        return aiCharacterRepository.findByMemberId(memberId)
            .map(AiCharacterResponse::from)
            .orElseThrow(() -> new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));
    }

    // EnumMap이 질문 선언 순서를 보장한다(검증을 통과한 답변이라 질문 중복은 없다)
    private Map<OnboardingQuestion, List<OnboardingOption>> toAnswersByQuestion(
        List<OnboardingAnswerGroupRequest> groups) {
        Map<OnboardingQuestion, List<OnboardingOption>> answers = new EnumMap<>(OnboardingQuestion.class);
        groups.forEach(group -> answers.put(group.questionCode(), List.copyOf(group.optionCodes())));
        return answers;
    }

}
