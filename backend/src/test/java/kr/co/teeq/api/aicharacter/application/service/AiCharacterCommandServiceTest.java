package kr.co.teeq.api.aicharacter.application.service;

import kr.co.teeq.api.common.core.constant.CharacterType;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
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
    private static final GeneratedAiCharacter GENERATED = new GeneratedAiCharacter("persona-1", CharacterType.CHARACTER_3, List.of("a", "b", "c"));

    @Mock
    private Member member;
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
    void 저장은_첫_생성이면_이름_없는_캐릭터를_만들고_생성됨을_돌려준다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        AiCharacterGenerationResult result = commandService.save(member, GENERATED, GROUPS);

        assertThat(result.created()).isTrue();
        assertThat(result.response().name()).isNull();
        assertThat(result.response().characterType()).isEqualTo(CharacterType.CHARACTER_3);
        assertThat(result.response().personalityTags()).containsExactly("a", "b", "c");
        // 캐릭터를 먼저 flush한 뒤 제출을 기록한다
        InOrder inOrder = inOrder(aiCharacterRepository, onboardingAnswerService);
        inOrder.verify(aiCharacterRepository).saveAndFlush(any(AiCharacter.class));
        inOrder.verify(onboardingAnswerService).recordSubmission(member, "persona-1", CharacterType.CHARACTER_3, List.of("a", "b", "c"), GROUPS);
    }

    @Test
    void 저장은_이름_있는_기존_캐릭터면_이름을_유지하고_생성되지_않음을_돌려준다() {
        AiCharacter existing = AiCharacter.of(member, CharacterType.CHARACTER_1, List.of("x", "y", "z"));
        existing.rename("티큐");
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(existing));

        AiCharacterGenerationResult result = commandService.save(member, GENERATED, GROUPS);

        assertThat(result.created()).isFalse();
        assertThat(result.response().name()).isEqualTo("티큐");
        assertThat(existing.getName()).isEqualTo("티큐");
        assertThat(existing.getCharacterType()).isEqualTo(CharacterType.CHARACTER_3);
        assertThat(existing.getPersonalityTags()).containsExactly("a", "b", "c");
        verify(aiCharacterRepository).saveAndFlush(existing);
    }

    @Test
    void 저장은_온보딩_제출을_기록한다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        commandService.save(member, GENERATED, GROUPS);

        verify(onboardingAnswerService).recordSubmission(member, "persona-1", CharacterType.CHARACTER_3, List.of("a", "b", "c"), GROUPS);
    }

    @Test
    void 저장에서_유니크_제약_위반이면_STATE_CONFLICT를_던진다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());
        given(aiCharacterRepository.saveAndFlush(any(AiCharacter.class)))
            .willThrow(new DataIntegrityViolationException("duplicate key value violates unique constraint "
                + "\"uq_ai_character_member\""));

        assertThatThrownBy(() -> commandService.save(member, GENERATED, GROUPS))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        verify(onboardingAnswerService, never()).recordSubmission(any(), any(), any(), anyList(), anyList());
    }

    @Test
    void 저장에서_다른_제약_위반이면_그대로_다시_던진다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());
        given(aiCharacterRepository.saveAndFlush(any(AiCharacter.class)))
            .willThrow(new DataIntegrityViolationException("value too long for type character varying(50)"));

        assertThatThrownBy(() -> commandService.save(member, GENERATED, GROUPS))
            .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void 이름_변경은_기존_캐릭터의_이름을_바꾼다() {
        AiCharacter existing = AiCharacter.of(member, CharacterType.CHARACTER_3, List.of("a", "b", "c"));
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(existing));

        AiCharacterResponse response = commandService.rename(member, "티큐");

        assertThat(existing.getName()).isEqualTo("티큐");
        assertThat(response).isEqualTo(new AiCharacterResponse("티큐", CharacterType.CHARACTER_3, List.of("a", "b", "c")));
    }

    @Test
    void 이름_변경에서_캐릭터가_없으면_AI_CHARACTER_NOT_FOUND를_던진다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> commandService.rename(member, "티큐"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
    }

}
