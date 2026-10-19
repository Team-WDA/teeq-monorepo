package kr.co.teeq.api.aicharacter.application.service;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import kr.co.teeq.api.aicharacter.application.dto.request.GenerateAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.request.RenameAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * AI 캐릭터 생성, 이름 확정, 조회. 생성은 답변 검증 -> AI 서버 호출 -> 저장 순서이며, AI 서버 호출 중에는 DB 트랜잭션을 열지 않는다.
 */
@Service
@RequiredArgsConstructor
public class AiCharacterService {

    private final OnboardingAnswerService onboardingAnswerService;
    private final AiCharacterGenerationPort aiCharacterGenerationPort;
    private final AiCharacterCommandService aiCharacterCommandService;
    private final AiCharacterRepository aiCharacterRepository;

    public AiCharacterGenerationResult generate(Member member, GenerateAiCharacterRequest request) {
        onboardingAnswerService.validateAnswers(request.onboardingAnswers());
        GeneratedAiCharacter generated = aiCharacterGenerationPort.generate(
            member.getId(), toAnswersByQuestion(request.onboardingAnswers()));
        return aiCharacterCommandService.save(member, generated, request.onboardingAnswers());
    }

    public AiCharacterResponse rename(Member member, RenameAiCharacterRequest request) {
        return aiCharacterCommandService.rename(member, request.name());
    }

    @Transactional(readOnly = true)
    public AiCharacterResponse get(Member member) {
        return aiCharacterRepository.findByMemberId(member.getId())
            .filter(AiCharacter::isNamed)
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
