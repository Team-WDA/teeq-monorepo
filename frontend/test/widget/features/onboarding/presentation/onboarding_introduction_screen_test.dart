import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

void main() {
  testWidgets('제목, 카드 문구 3개, 버튼이 보이고 뒤로 가기는 없다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingIntroductionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이제\n너만의 티크를\n만들 차례야!'), findsOneWidget);
    expect(find.text('너에 대해 조금 더 알아보고'), findsOneWidget);
    expect(find.text('어떤 대화를 좋아하는지 말해주면'), findsOneWidget);
    expect(find.text('너만의 티크가 준비 돼!'), findsOneWidget);
    expect(find.text('나만의 티크 만들기'), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });

  testWidgets(
    'tapping start button starts first-time flow and opens question screen',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.onboarding,
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (_, _) => const OnboardingIntroductionScreen(),
          ),
          GoRoute(
            path: AppRoutes.onboardingQuestions,
            builder: (_, _) => const Text('질문 스텁'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        characterSetupFlowControllerProvider.notifier,
      )..start(CharacterSetupMode.edit);
      controller.toggleOption(OnboardingQuestion.relationship.options.first);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('나만의 티크 만들기'));
      await tester.pumpAndSettle();

      expect(find.text('질문 스텁'), findsOneWidget);
      final state = container.read(characterSetupFlowControllerProvider);
      expect(state.mode, CharacterSetupMode.firstTime);
      expect(
        state.selections.selectedFor(OnboardingQuestion.relationship),
        isEmpty,
      );
    },
  );
}
