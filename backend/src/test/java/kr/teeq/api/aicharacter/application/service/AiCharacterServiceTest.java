package kr.teeq.api.aicharacter.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.aicharacter.application.dto.request.SubmitAiCharacterRequest;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AiCharacterServiceTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();
    private static final List<OnboardingAnswerGroupRequest> GROUPS = List.of(
        new OnboardingAnswerGroupRequest(OnboardingQuestion.RELATIONSHIP,
            List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));
    private static final SubmitAiCharacterRequest REQUEST = new SubmitAiCharacterRequest("티큐", GROUPS);
    private static final GeneratedAiCharacter GENERATED = new GeneratedAiCharacter(7, List.of("a", "b", "c"));

    @Mock
    private OnboardingAnswerService onboardingAnswerService;
    @Mock
    private AiCharacterGenerationPort aiCharacterGenerationPort;
    @Mock
    private AiCharacterCommandService aiCharacterCommandService;
    @Mock
    private AiCharacterRepository aiCharacterRepository;

    private AiCharacterService aiCharacterService;

    @BeforeEach
    void setUp() {
        aiCharacterService = new AiCharacterService(onboardingAnswerService, aiCharacterGenerationPort,
            aiCharacterCommandService, aiCharacterRepository);
    }

    @Test
    void 검증_생성_저장_순서로_호출하고_저장_결과를_그대로_돌려준다() {
        AiCharacterSubmitResult saved = new AiCharacterSubmitResult(
            new AiCharacterResponse("티큐", 7, List.of("a", "b", "c")), true);
        given(aiCharacterGenerationPort.generate(eq(MEMBER_ID), eq("티큐"), any())).willReturn(GENERATED);
        given(aiCharacterCommandService.save(MEMBER_ID, "티큐", GENERATED, GROUPS)).willReturn(saved);

        AiCharacterSubmitResult result = aiCharacterService.submit(MEMBER_ID, REQUEST);

        assertThat(result).isSameAs(saved);
        InOrder inOrder = inOrder(onboardingAnswerService, aiCharacterGenerationPort, aiCharacterCommandService);
        inOrder.verify(onboardingAnswerService).validateAnswers(MEMBER_ID, GROUPS);
        inOrder.verify(aiCharacterGenerationPort).generate(MEMBER_ID, "티큐",
            Map.of(OnboardingQuestion.RELATIONSHIP, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));
        inOrder.verify(aiCharacterCommandService).save(MEMBER_ID, "티큐", GENERATED, GROUPS);
    }

    @Test
    void 답변_검증에_실패하면_AI_서버를_호출하지_않고_저장하지_않는다() {
        willThrow(new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE))
            .given(onboardingAnswerService).validateAnswers(MEMBER_ID, GROUPS);

        assertThatThrownBy(() -> aiCharacterService.submit(MEMBER_ID, REQUEST))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE));
        verifyNoInteractions(aiCharacterGenerationPort, aiCharacterCommandService);
    }

    @Test
    void AI_서버_호출에_실패하면_저장하지_않는다() {
        given(aiCharacterGenerationPort.generate(eq(MEMBER_ID), eq("티큐"), any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        assertThatThrownBy(() -> aiCharacterService.submit(MEMBER_ID, REQUEST))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
        verifyNoInteractions(aiCharacterCommandService);
    }

    @Test
    void 조회는_저장된_캐릭터를_응답으로_바꾸고_없으면_AI_CHARACTER_NOT_FOUND를_던진다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID))
            .willReturn(Optional.of(AiCharacter.of(MEMBER_ID, "티큐", 7, List.of("a", "b", "c"))));

        assertThat(aiCharacterService.get(MEMBER_ID))
            .isEqualTo(new AiCharacterResponse("티큐", 7, List.of("a", "b", "c")));

        UUID otherMemberId = UUID.randomUUID();
        given(aiCharacterRepository.findByMemberId(otherMemberId)).willReturn(Optional.empty());
        assertThatThrownBy(() -> aiCharacterService.get(otherMemberId))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
    }

}
