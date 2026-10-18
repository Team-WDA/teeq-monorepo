package kr.co.teeq.api.aicharacter.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class AiCharacterCommandServiceTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();
    private static final List<OnboardingAnswerGroupRequest> GROUPS = List.of();
    private static final GeneratedAiCharacter GENERATED = new GeneratedAiCharacter(7, List.of("a", "b", "c"));

    @Mock
    private AiCharacterRepository aiCharacterRepository;
    @Mock
    private OnboardingAnswerService onboardingAnswerService;

    private AiCharacterCommandService commandService;

    @BeforeEach
    void setUp() {
        commandService = new AiCharacterCommandService(aiCharacterRepository, onboardingAnswerService);
    }

    @Test
    void 캐릭터가_없으면_새로_저장하고_답변을_저장한_뒤_created를_돌려준다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        AiCharacterSubmitResult result = commandService.save(MEMBER_ID, "티큐", GENERATED, GROUPS);

        assertThat(result.created()).isTrue();
        assertThat(result.response().name()).isEqualTo("티큐");
        assertThat(result.response().characterNumber()).isEqualTo(7);
        assertThat(result.response().personalityTags()).containsExactly("a", "b", "c");
        // 답변 교체가 영속성 컨텍스트를 비우므로 캐릭터를 먼저 flush한다
        InOrder inOrder = inOrder(aiCharacterRepository, onboardingAnswerService);
        inOrder.verify(aiCharacterRepository).saveAndFlush(any(AiCharacter.class));
        inOrder.verify(onboardingAnswerService).replaceAnswers(MEMBER_ID, GROUPS);
    }

    @Test
    void 캐릭터가_있으면_같은_행을_갱신하고_created를_false로_돌려준다() {
        AiCharacter existing = AiCharacter.of(MEMBER_ID, "옛이름", 1, List.of("x", "y", "z"));
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(existing));

        AiCharacterSubmitResult result = commandService.save(MEMBER_ID, "새이름", GENERATED, GROUPS);

        assertThat(result.created()).isFalse();
        assertThat(existing.getName()).isEqualTo("새이름");
        assertThat(existing.getCharacterNumber()).isEqualTo(7);
        assertThat(existing.getPersonalityTags()).containsExactly("a", "b", "c");
        verify(aiCharacterRepository).saveAndFlush(existing);
        verify(onboardingAnswerService).replaceAnswers(MEMBER_ID, GROUPS);
    }

    @Test
    void 회원_unique_제약_위반이면_STATE_CONFLICT로_바꾸고_답변은_저장하지_않는다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());
        given(aiCharacterRepository.saveAndFlush(any(AiCharacter.class)))
            .willThrow(new DataIntegrityViolationException("duplicate key value violates unique constraint "
                + "\"uq_ai_character_member\""));

        assertThatThrownBy(() -> commandService.save(MEMBER_ID, "티큐", GENERATED, GROUPS))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        verify(onboardingAnswerService, never()).replaceAnswers(any(), any());
    }

    @Test
    void 다른_제약_위반은_STATE_CONFLICT로_바꾸지_않고_그대로_던진다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());
        given(aiCharacterRepository.saveAndFlush(any(AiCharacter.class)))
            .willThrow(new DataIntegrityViolationException("value too long for type character varying(50)"));

        assertThatThrownBy(() -> commandService.save(MEMBER_ID, "티큐", GENERATED, GROUPS))
            .isInstanceOf(DataIntegrityViolationException.class);
    }

}
