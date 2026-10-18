import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';

part 'character_setup_flow_controller.g.dart';

/// 캐릭터 설정 흐름 상태를 보관한다. 진입점이 [start]로 모드를 정하고 흐름이 끝나면 [reset]한다.
@Riverpod(keepAlive: true)
class CharacterSetupFlowController extends _$CharacterSetupFlowController {
  @override
  CharacterSetupFlowState build() => CharacterSetupFlowState.initial;

  /// 이전 상태를 모두 비우고 [mode]로 흐름을 시작한다.
  void start(CharacterSetupMode mode) {
    state = CharacterSetupFlowState.initial.copyWith(mode: mode);
  }

  void toggleOption(OnboardingOption option) {
    state = state.copyWith(selections: state.selections.toggle(option));
  }

  /// 다음 질문으로 넘어간다. 마지막 질문이면 넘어가지 않고 false를 돌려준다.
  bool goToNextQuestion() {
    if (state.questionIndex >= OnboardingQuestion.values.length - 1) {
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
