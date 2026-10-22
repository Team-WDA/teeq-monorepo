import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/option_card/selectable_option_card.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_question_screen.dart';

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  CharacterSetupMode mode = CharacterSetupMode.firstTime,
  int startIndex = 0,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.onboardingQuestions,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('홈 스텁')),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (_, _) => const OnboardingQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingGenerating,
        builder: (_, _) => const Text('생성 중 스텁'),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final controller = container.read(
    characterSetupFlowControllerProvider.notifier,
  )..start(mode);
  for (var index = 0; index < startIndex; index++) {
    controller.goToNextQuestion();
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapOption(WidgetTester tester, OnboardingOption option) async {
  await tester.ensureVisible(find.text(option.label));
  await tester.pump();
  await tester.tap(find.text(option.label));
  await tester.pump();
}

VoidCallback? _nextOnPressed(WidgetTester tester) => tester
    .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
    .onPressed;

void main() {
  testWidgets('shows first question title description and options', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('우리,\n어떤 사이로 지낼까?'), findsOneWidget);
    expect(find.textContaining('(단일 선택)'), findsOneWidget);
    expect(find.byType(SelectableOptionCard), findsNWidgets(4));
    expect(_nextOnPressed(tester), isNull);
  });

  testWidgets(
    'selecting single option enables next and next advances to second question',
    (tester) async {
      await _pumpScreen(tester);

      await _tapOption(tester, OnboardingOption.relationshipCloseFriend);
      expect(_nextOnPressed(tester), isNotNull);

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text(OnboardingQuestion.personality.title), findsOneWidget);
      expect(_nextOnPressed(tester), isNull);
    },
  );

  testWidgets(
    'multiple choice question enables next with one selection and disables again after deselecting',
    (tester) async {
      await _pumpScreen(tester, startIndex: 6);
      const option = OnboardingOption.avoidBehaviorInterrupting;

      expect(find.textContaining('(복수 선택)'), findsOneWidget);
      await _tapOption(tester, option);
      expect(_nextOnPressed(tester), isNotNull);

      await _tapOption(tester, option);
      expect(_nextOnPressed(tester), isNull);
    },
  );

  testWidgets('last question next navigates to generating route', (
    tester,
  ) async {
    await _pumpScreen(tester, startIndex: 6);
    await _tapOption(tester, OnboardingOption.avoidBehaviorInterrupting);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('생성 중 스텁'), findsOneWidget);
  });

  testWidgets(
    'system back on second question returns to first and keeps selection',
    (tester) async {
      final container = await _pumpScreen(tester);
      await _tapOption(tester, OnboardingOption.relationshipCloseFriend);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(OnboardingQuestion.relationship.title), findsOneWidget);
      expect(
        container
            .read(characterSetupFlowControllerProvider)
            .selections
            .selectedFor(OnboardingQuestion.relationship),
        {OnboardingOption.relationshipCloseFriend},
      );
      expect(_nextOnPressed(tester), isNotNull);
    },
  );

  testWidgets('system back on first question in firstTime mode does nothing', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingQuestionScreen), findsOneWidget);
    expect(find.text('홈 스텁'), findsNothing);
  });

  testWidgets(
    'system back on first question in edit mode resets flow and navigates home',
    (tester) async {
      final container = await _pumpScreen(
        tester,
        mode: CharacterSetupMode.edit,
      );
      await _tapOption(tester, OnboardingOption.relationshipCloseFriend);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('홈 스텁'), findsOneWidget);
      final state = container.read(characterSetupFlowControllerProvider);
      expect(state.mode, CharacterSetupMode.firstTime);
      expect(
        state.selections.isAnswered(OnboardingQuestion.relationship),
        isFalse,
      );
    },
  );
}
