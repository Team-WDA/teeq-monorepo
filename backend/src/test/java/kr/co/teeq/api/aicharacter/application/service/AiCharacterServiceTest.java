package kr.co.teeq.api.aicharacter.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.request.GenerateAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.request.RenameAiCharacterRequest;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.service.OnboardingAnswerService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
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
    private static final GenerateAiCharacterRequest REQUEST = new GenerateAiCharacterRequest(GROUPS);
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
    void 생성은_AI_서버_호출_전에_답변을_검증한다() {
        willThrow(new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE))
            .given(onboardingAnswerService).validateAnswers(MEMBER_ID, GROUPS);

        assertThatThrownBy(() -> aiCharacterService.generate(MEMBER_ID, REQUEST))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE));
        verifyNoInteractions(aiCharacterGenerationPort, aiCharacterCommandService);
    }

    @Test
    void 생성은_이름_없이_답변만_포트에_전달한다() {
        AiCharacterGenerationResult saved = new AiCharacterGenerationResult(
            new AiCharacterResponse(null, 7, List.of("a", "b", "c")), true);
        given(aiCharacterGenerationPort.generate(any(), any())).willReturn(GENERATED);
        given(aiCharacterCommandService.save(MEMBER_ID, GENERATED, GROUPS)).willReturn(saved);

        AiCharacterGenerationResult result = aiCharacterService.generate(MEMBER_ID, REQUEST);

        assertThat(result).isSameAs(saved);
        InOrder inOrder = inOrder(onboardingAnswerService, aiCharacterGenerationPort, aiCharacterCommandService);
        inOrder.verify(onboardingAnswerService).validateAnswers(MEMBER_ID, GROUPS);
        inOrder.verify(aiCharacterGenerationPort).generate(MEMBER_ID,
            Map.of(OnboardingQuestion.RELATIONSHIP, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));
        inOrder.verify(aiCharacterCommandService).save(MEMBER_ID, GENERATED, GROUPS);
    }

    @Test
    void 생성에서_AI_서버_호출이_실패하면_저장하지_않는다() {
        given(aiCharacterGenerationPort.generate(any(), any()))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        assertThatThrownBy(() -> aiCharacterService.generate(MEMBER_ID, REQUEST))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
        verifyNoInteractions(aiCharacterCommandService);
    }

    @Test
    void 조회에서_이름이_없는_캐릭터면_AI_CHARACTER_NOT_FOUND를_던진다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID))
            .willReturn(Optional.of(AiCharacter.of(MEMBER_ID, 7, List.of("a", "b", "c"))));

        assertThatThrownBy(() -> aiCharacterService.get(MEMBER_ID))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
    }

    @Test
    void 조회에서_캐릭터가_없으면_AI_CHARACTER_NOT_FOUND를_던진다() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> aiCharacterService.get(MEMBER_ID))
            .isInstanceOfSatisfying(CustomException.class, exception ->
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
    }

    @Test
    void 조회에서_이름이_있는_캐릭터면_응답을_돌려준다() {
        AiCharacter aiCharacter = AiCharacter.of(MEMBER_ID, 7, List.of("a", "b", "c"));
        aiCharacter.rename("티큐");
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(aiCharacter));

        assertThat(aiCharacterService.get(MEMBER_ID))
            .isEqualTo(new AiCharacterResponse("티큐", 7, List.of("a", "b", "c")));
    }

    @Test
    void 이름_변경은_커맨드_서비스에_위임한다() {
        AiCharacterResponse renamed = new AiCharacterResponse("티큐", 7, List.of("a", "b", "c"));
        given(aiCharacterCommandService.rename(MEMBER_ID, "티큐")).willReturn(renamed);

        assertThat(aiCharacterService.rename(MEMBER_ID, new RenameAiCharacterRequest("티큐"))).isSameAs(renamed);
    }

}
