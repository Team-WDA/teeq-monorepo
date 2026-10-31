import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';

const _character = AiCharacter(
  name: null,
  characterType: CharacterType.character3,
  personalityTags: ['다정한', '차분한', '든든한'],
);

final _relationship = testOnboardingQuestion('RELATIONSHIP');
final _closeFriend = testOnboardingOption('RELATIONSHIP_CLOSE_FRIEND');
final _lifeMentor = testOnboardingOption('RELATIONSHIP_LIFE_MENTOR');

ProviderContainer _createContainer() {
  final container = ProviderContainer(
    overrides: [
      onboardingCatalogRepositoryProvider.overrideWithValue(
        FakeOnboardingCatalogRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// 카탈로그를 불러 둔 컨테이너. 질문 이동은 카탈로그 질문 수를 기준으로 한다.
Future<ProviderContainer> _createContainerWithCatalog() async {
  final container = _createContainer();
  await container.read(onboardingCatalogProvider.future);
  return container;
}

void main() {
  test('start_setsModeAndClearsPreviousState', () async {
    final container = await _createContainerWithCatalog();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.start(CharacterSetupMode.firstTime);
    controller.toggleOption(_relationship, _closeFriend);
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

    controller.toggleOption(_relationship, _lifeMentor);

    expect(
      container.read(characterSetupFlowControllerProvider).selections,
      const OnboardingSelections.empty().toggle(_relationship, _lifeMentor),
    );
  });

  test('goToNextQuestion_advancesUntilLast_thenReturnsFalse', () async {
    final container = await _createContainerWithCatalog();
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

  test('goToPreviousQuestion_keepsSelections', () async {
    final container = await _createContainerWithCatalog();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    controller.toggleOption(_relationship, _closeFriend);
    controller.goToNextQuestion();

    expect(controller.goToPreviousQuestion(), isTrue);

    final state = container.read(characterSetupFlowControllerProvider);
    expect(state.questionIndex, 0);
    expect(
      state.selections,
      const OnboardingSelections.empty().toggle(_relationship, _closeFriend),
    );
  });

  test('goToNextQuestion_withoutCatalog_returnsFalse', () {
    final container = _createContainer();
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );

    expect(controller.goToNextQuestion(), isFalse);
    expect(
      container.read(characterSetupFlowControllerProvider).questionIndex,
      0,
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
    controller.toggleOption(_relationship, _closeFriend);
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
    controller.toggleOption(_relationship, _closeFriend);
    controller.recordCharacter(_character);

    container.read(authStatusControllerProvider.notifier).markSignedOut();

    expect(
      container.read(characterSetupFlowControllerProvider),
      CharacterSetupFlowState.initial,
    );
  });
}
