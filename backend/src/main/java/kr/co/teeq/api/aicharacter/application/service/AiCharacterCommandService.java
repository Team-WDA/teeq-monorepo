package kr.co.teeq.api.aicharacter.application.service;

import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * AI 캐릭터와 온보딩 답변을 한 트랜잭션으로 저장한다. AI 서버 호출은 이 트랜잭션 밖({@link AiCharacterService})에서 한다.
 */
@Service
@RequiredArgsConstructor
public class AiCharacterCommandService {

    // 마이그레이션의 unique 제약 이름과 같아야 한다. 동시 제출로 제약이 먼저 걸린 경우에만 409로 바꾼다
    private static final String MEMBER_UNIQUE_CONSTRAINT_NAME = "uq_ai_character_member";

    private final AiCharacterRepository aiCharacterRepository;
    private final OnboardingAnswerService onboardingAnswerService;

    @Transactional
    public AiCharacterSubmitResult save(UUID memberId, String name, GeneratedAiCharacter generated,
        List<OnboardingAnswerGroupRequest> groups) {
        AiCharacter existing = aiCharacterRepository.findByMemberId(memberId).orElse(null);
        boolean created = existing == null;
        AiCharacter aiCharacter = created
            ? AiCharacter.of(memberId, name, generated.characterNumber(), generated.personalityTags())
            : existing;
        if (!created) {
            aiCharacter.reset(name, generated.characterNumber(), generated.personalityTags());
        }
        try {
            aiCharacterRepository.saveAndFlush(aiCharacter);
        } catch (DataIntegrityViolationException exception) {
            String message = String.valueOf(exception.getMostSpecificCause().getMessage());
            if (message.contains(MEMBER_UNIQUE_CONSTRAINT_NAME)) {
                throw new CustomException(ErrorCode.STATE_CONFLICT, exception);
            }
            throw exception;
        }
        // 캐릭터 변경은 위 saveAndFlush로 이미 반영됐다. 답변 교체가 영속성 컨텍스트를 비우기 전에 응답을 만들어 둔다
        AiCharacterResponse response = AiCharacterResponse.from(aiCharacter);
        onboardingAnswerService.replaceAnswers(memberId, groups);
        return new AiCharacterSubmitResult(response, created);
    }

}
