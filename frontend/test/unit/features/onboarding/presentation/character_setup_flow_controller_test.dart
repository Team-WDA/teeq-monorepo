import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';

const _character = AiCharacter(
  name: null,
  characterNumber: 3,
  personalityTags: ['다정한', '차분한', '든든한'],
);

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('start_setsModeAndClearsPreviousState', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.start(CharacterSetupMode.firstTime);
    controller.toggleOption(OnboardingOption.relationshipCloseFriend);
    controller.goToNextQuestion();
    controller.recordCharacter(_character);

    controller.start(CharacterSetupMode.edit);

    final state = container.read(characterSetupFlowControllerProvider);
    expect(state.mode, CharacterSetupMode.edit);
    expect(state.questionIndex, 0);
    expect(state.selections, const OnboardingSelections.empty());
    expect(state.character, isNull);
  });

  test('toggleOption_updatesSelections', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );

    controller.toggleOption(OnboardingOption.relationshipLifeMentor);

    expect(
      container.read(characterSetupFlowControllerProvider).selections,
      const OnboardingSelections.empty().toggle(
        OnboardingOption.relationshipLifeMentor,
      ),
    );
  });

  test('goToNextQuestion_advancesUntilLast_thenReturnsFalse', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );

    for (var index = 1; index <= 6; index++) {
      expect(controller.goToNextQuestion(), isTrue);
      expect(
        container.read(characterSetupFlowControllerProvider).questionIndex,
        index,
      );
    }
    expect(controller.goToNextQuestion(), isFalse);
    expect(
      container.read(characterSetupFlowControllerProvider).questionIndex,
      6,
    );
  });

  test('goToPreviousQuestion_keepsSelections', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.toggleOption(OnboardingOption.relationshipCloseFriend);
    controller.goToNextQuestion();

    expect(controller.goToPreviousQuestion(), isTrue);

    final state = container.read(characterSetupFlowControllerProvider);
    expect(state.questionIndex, 0);
    expect(
      state.selections,
      const OnboardingSelections.empty().toggle(
        OnboardingOption.relationshipCloseFriend,
      ),
    );
  });

  test('goToPreviousQuestion_atFirst_returnsFalse', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );

    expect(controller.goToPreviousQuestion(), isFalse);
    expect(
      container.read(characterSetupFlowControllerProvider).questionIndex,
      0,
    );
  });

  test('recordCharacter_storesCharacter', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );

    controller.recordCharacter(_character);

    expect(
      container.read(characterSetupFlowControllerProvider).character,
      _character,
    );
  });

  test('reset_returnsToInitialState', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.start(CharacterSetupMode.edit);
    controller.toggleOption(OnboardingOption.relationshipCloseFriend);
    controller.recordCharacter(_character);

    controller.reset();

    expect(
      container.read(characterSetupFlowControllerProvider),
      CharacterSetupFlowState.initial,
    );
  });

  test('flowState_resetsWhenAuthStatusLeavesSignedIn', () {
    final container = _createContainer();
    container.read(authStatusControllerProvider.notifier).markSignedIn();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.start(CharacterSetupMode.edit);
    controller.toggleOption(OnboardingOption.relationshipCloseFriend);
    controller.recordCharacter(_character);

    container.read(authStatusControllerProvider.notifier).markSignedOut();

    expect(
      container.read(characterSetupFlowControllerProvider),
      CharacterSetupFlowState.initial,
    );
  });
}
