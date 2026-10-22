import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_generating_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';

import '../../../../support/fake_ai_character_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _generated = AiCharacter(
  name: null,
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);
const _stageTwoMessage = '말투와 분위기를 맞추고 있어.';
const _stageThreeMessage = '마지막 형태를 다듬는 중!';
const _crossfadeSettle = Duration(milliseconds: 500);

class _Harness {
  _Harness(this.container, this.repository, this.errorHandler);

  final ProviderContainer container;
  final FakeAiCharacterRepository repository;
  final _RecordingErrorHandler errorHandler;
}

Future<_Harness> _pumpScreen(
  WidgetTester tester,
  FakeAiCharacterRepository repository,
) async {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    overrides: [
      aiCharacterRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  final controller = container.read(
    characterSetupFlowControllerProvider.notifier,
  )..start(CharacterSetupMode.firstTime);
  for (final question in OnboardingQuestion.values) {
    controller.toggleOption(question.options.first);
  }
  final router = GoRouter(
    initialLocation: AppRoutes.onboardingGenerating,
    routes: [
      GoRoute(
        path: AppRoutes.onboardingGenerating,
        builder: (_, _) => const CharacterGeneratingScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (_, _) => const Text('질문 스텁'),
      ),
      GoRoute(
        path: AppRoutes.characterName,
        builder: (_, _) => const Text('이름 스텁'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  return _Harness(container, repository, errorHandler);
}

void main() {
  testWidgets('calls generate once with selected answers on entry', (
    tester,
  ) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateResult: _generated),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(harness.repository.generateCalls, hasLength(1));
    expect(
      harness.repository.generateCalls.single,
      harness.container.read(characterSetupFlowControllerProvider).selections,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'shows stage one at start then stage two at 1500ms then stage three at 3000ms',
    (tester) async {
      await _pumpScreen(
        tester,
        FakeAiCharacterRepository(
          generateGate: Completer<void>(),
          generateResult: _generated,
        ),
      );
      expect(find.text(_stageTwoMessage), findsNothing);
      expect(find.text(_stageThreeMessage), findsNothing);

      await tester.pump(const Duration(milliseconds: 1499));
      expect(find.text(_stageTwoMessage), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(_crossfadeSettle);
      expect(find.text(_stageTwoMessage), findsOneWidget);
      expect(find.text(_stageThreeMessage), findsNothing);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(_crossfadeSettle);
      expect(find.text(_stageTwoMessage), findsNothing);
      expect(find.text(_stageThreeMessage), findsOneWidget);
    },
  );

  testWidgets(
    'does not navigate before 4500ms even if response arrived earlier',
    (tester) async {
      await _pumpScreen(
        tester,
        FakeAiCharacterRepository(generateResult: _generated),
      );

      await tester.pump(const Duration(milliseconds: 4499));
      await tester.pump();
      expect(find.text('이름 스텁'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('이름 스텁'), findsOneWidget);
    },
  );

  testWidgets(
    'stays on stage three until response when response is slower than 4500ms',
    (tester) async {
      final gate = Completer<void>();
      await _pumpScreen(
        tester,
        FakeAiCharacterRepository(
          generateGate: gate,
          generateResult: _generated,
        ),
      );

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('이름 스텁'), findsNothing);
      expect(find.text(_stageThreeMessage), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('이름 스텁'), findsOneWidget);
    },
  );

  testWidgets('records generated character in flow state before navigating', (
    tester,
  ) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateResult: _generated),
    );
    expect(
      harness.container.read(characterSetupFlowControllerProvider).character,
      isNull,
    );

    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pumpAndSettle();

    expect(
      harness.container.read(characterSetupFlowControllerProvider).character,
      _generated,
    );
  });

  testWidgets(
    'toast-class failure reports error and returns to question screen with selections kept',
    (tester) async {
      const failure = ApiException(
        errorCode: ErrorCode.aiServerUnavailable,
        httpStatus: 502,
      );
      final harness = await _pumpScreen(
        tester,
        FakeAiCharacterRepository(generateError: failure),
      );
      await tester.pumpAndSettle();

      expect(harness.errorHandler.handledErrors, [failure]);
      expect(find.text('질문 스텁'), findsOneWidget);
      expect(
        harness.container
            .read(characterSetupFlowControllerProvider)
            .selections
            .isComplete,
        isTrue,
      );
    },
  );

  testWidgets('network failure reports error and does not navigate itself', (
    tester,
  ) async {
    const failure = NetworkException(NetworkFailureKind.connection);
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateError: failure),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, [failure]);
    expect(find.text('질문 스텁'), findsNothing);
    expect(find.text('이름 스텁'), findsNothing);
    expect(find.byType(CharacterGeneratingScreen), findsOneWidget);
  });

  testWidgets('back button is blocked', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        generateGate: Completer<void>(),
        generateResult: _generated,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(CharacterGeneratingScreen), findsOneWidget);
  });
}
