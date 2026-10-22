import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';

const _openDialogLabel = '팝업 열기';

Future<ProviderContainer> _pumpHost(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => showCharacterEditConfirmationDialog(
              context,
              characterName: '티티',
            ),
            child: const Text(_openDialogLabel),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (_, _) => const Text('질문 스텁'),
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
  await tester.tap(find.text(_openDialogLabel));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows name in title and body', (tester) async {
    await _pumpHost(tester);

    expect(find.text('걱정 마! 우리의 기억은 그대로야.'), findsOneWidget);
    expect(find.text('티티의 성향을 다시 설정할까?'), findsOneWidget);
    expect(
      find.text('처음 만날 때와 같은 질문이 다시 나타나요.\n새로운 답변에 맞춰 티티의 성향과\n대화 스타일이 달라져요.'),
      findsOneWidget,
    );
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('다시 설정하기'), findsOneWidget);
  });

  testWidgets('close and cancel only dismiss the dialog', (tester) async {
    final container = await _pumpHost(tester);

    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
    expect(find.text(_openDialogLabel), findsOneWidget);

    await tester.tap(find.text(_openDialogLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
    expect(find.text(_openDialogLabel), findsOneWidget);
    expect(find.text('질문 스텁'), findsNothing);
    expect(
      container.read(characterSetupFlowControllerProvider).mode,
      CharacterSetupMode.firstTime,
    );
  });

  testWidgets(
    'redo button dismisses dialog starts edit mode and navigates to questions',
    (tester) async {
      final container = await _pumpHost(tester);

      await tester.tap(find.text('다시 설정하기'));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
      expect(find.text('질문 스텁'), findsOneWidget);
      final state = container.read(characterSetupFlowControllerProvider);
      expect(state.mode, CharacterSetupMode.edit);
      expect(state.selections.isComplete, isFalse);
      expect(state.questionIndex, 0);
    },
  );
}
