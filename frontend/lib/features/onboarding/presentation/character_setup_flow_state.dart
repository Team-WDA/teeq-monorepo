import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

part 'character_setup_flow_state.freezed.dart';

/// 캐릭터 설정 흐름(질문 → 생성 → 이름 → 결과)이 화면 사이에 공유하는 상태.
@freezed
abstract class CharacterSetupFlowState with _$CharacterSetupFlowState {
  const factory CharacterSetupFlowState({
    required CharacterSetupMode mode,
    required int questionIndex,
    required OnboardingSelections selections,
    AiCharacter? character,
  }) = _CharacterSetupFlowState;

  static const CharacterSetupFlowState initial = CharacterSetupFlowState(
    mode: CharacterSetupMode.firstTime,
    questionIndex: 0,
    selections: OnboardingSelections.empty(),
  );
}
