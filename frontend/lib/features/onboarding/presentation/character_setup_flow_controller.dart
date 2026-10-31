import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';

part 'character_setup_flow_controller.g.dart';

/// 캐릭터 설정 흐름 상태를 보관한다. 진입점이 [start]로 모드를 정하고 흐름이 끝나면 [reset]한다.
@Riverpod(keepAlive: true)
class CharacterSetupFlowController extends _$CharacterSetupFlowController {
  @override
  CharacterSetupFlowState build() {
    // 로그아웃·세션 만료·탈퇴 뒤에 다음 계정으로 이전 흐름 상태가 새지 않게 비운다.
    ref.listen(authStatusControllerProvider, (previous, next) {
      if (next != AuthStatus.signedIn) {
        reset();
      }
    });
    return CharacterSetupFlowState.initial;
  }

  /// 이전 상태를 모두 비우고 [mode]로 흐름을 시작한다.
  void start(CharacterSetupMode mode) {
    state = CharacterSetupFlowState.initial.copyWith(mode: mode);
  }

  void toggleOption(OnboardingQuestion question, OnboardingOption option) {
    state = state.copyWith(
      selections: state.selections.toggle(question, option),
    );
  }

  /// 다음 질문으로 넘어간다. 마지막 질문이거나 카탈로그가 아직 없으면 넘어가지 않고 false를 돌려준다.
  bool goToNextQuestion() {
    final catalog = ref.read(onboardingCatalogProvider).value;
    if (catalog == null ||
        state.questionIndex >= catalog.questions.length - 1) {
      return false;
    }
    state = state.copyWith(questionIndex: state.questionIndex + 1);
    return true;
  }

  /// 이전 질문으로 돌아간다(선택은 유지). 첫 질문이면 false를 돌려준다.
  bool goToPreviousQuestion() {
    if (state.questionIndex <= 0) {
      return false;
    }
    state = state.copyWith(questionIndex: state.questionIndex - 1);
    return true;
  }

  void recordCharacter(AiCharacter character) {
    state = state.copyWith(character: character);
  }

  void reset() {
    state = CharacterSetupFlowState.initial;
  }
}
