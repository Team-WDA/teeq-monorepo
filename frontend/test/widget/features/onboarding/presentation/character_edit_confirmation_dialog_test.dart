import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/network/retry_policy.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/rounded_pill_button.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _openDialogLabel = '팝업 열기';
const _redoLabel = '다시 설정하기';

/// 대기 중에는 글자 대신 스피너가 보이므로 버튼의 [RoundedPillButton.label]로 찾는다.
final Finder _redoButtonFinder = find.byWidgetPredicate(
  (widget) => widget is RoundedPillButton && widget.label == _redoLabel,
);

RoundedPillButton _redoButton(WidgetTester tester) =>
    tester.widget<RoundedPillButton>(_redoButtonFinder);

Future<ProviderContainer> _pumpHost(
  WidgetTester tester, {
  FakeOnboardingCatalogRepository? catalogRepository,
  ErrorHandler? errorHandler,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    // 앱과 같은 재시도 정책을 써서 예상 밖 오류가 자동 재시도되지 않게 한다.
    retry: providerRetry,
    overrides: [
      onboardingCatalogRepositoryProvider.overrideWithValue(
        catalogRepository ?? FakeOnboardingCatalogRepository(),
      ),
      if (errorHandler != null)
        errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
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
              characterType: CharacterType.character3,
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
      expect(state.selections.isComplete(testOnboardingCatalog), isFalse);
      expect(state.questionIndex, 0);
    },
  );

  testWidgets(
    'redo button is loading while catalog loads and blocks re-entry',
    (tester) async {
      final gate = Completer<void>();
      final catalogRepository = FakeOnboardingCatalogRepository(gate: gate);
      await _pumpHost(tester, catalogRepository: catalogRepository);

      await tester.tap(find.text(_redoLabel));
      await tester.pump();

      expect(_redoButton(tester).isLoading, isTrue);
      expect(find.byType(CharacterEditConfirmationDialog), findsOneWidget);
      await tester.tap(_redoButtonFinder);
      await tester.pump();
      expect(catalogRepository.fetchCount, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );

  testWidgets(
    'catalog failure keeps dialog open reports error and retry refetches',
    (tester) async {
      final failure = UnexpectedException(StateError('카탈로그 실패'));
      final errorHandler = _RecordingErrorHandler();
      final catalogRepository = FakeOnboardingCatalogRepository(
        firstFetchError: failure,
      );
      final container = await _pumpHost(
        tester,
        catalogRepository: catalogRepository,
        errorHandler: errorHandler,
      );

      await tester.tap(find.text(_redoLabel));
      await tester.pumpAndSettle();

      expect(errorHandler.handledErrors, [failure]);
      expect(find.byType(CharacterEditConfirmationDialog), findsOneWidget);
      expect(find.text('질문 스텁'), findsNothing);
      expect(_redoButton(tester).isLoading, isFalse);
      expect(
        container.read(characterSetupFlowControllerProvider).mode,
        CharacterSetupMode.firstTime,
      );

      await tester.tap(find.text(_redoLabel));
      await tester.pumpAndSettle();

      expect(catalogRepository.fetchCount, 2);
      expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );

  testWidgets(
    'cached catalog error left by a dismissed dialog is refetched on next tap',
    (tester) async {
      final failure = UnexpectedException(StateError('카탈로그 실패'));
      final errorHandler = _RecordingErrorHandler();
      final catalogRepository = FakeOnboardingCatalogRepository(
        firstFetchError: failure,
      );
      final container = await _pumpHost(
        tester,
        catalogRepository: catalogRepository,
        errorHandler: errorHandler,
      );
      // 이전 팝업이 실패한 채 닫혀 invalidate하지 못한 상황을 만든다.
      container.read(onboardingCatalogProvider.future).ignore();
      await tester.pump();
      expect(container.read(onboardingCatalogProvider).hasError, isTrue);

      await tester.tap(find.text(_redoLabel));
      await tester.pumpAndSettle();

      expect(catalogRepository.fetchCount, 2);
      expect(errorHandler.handledErrors, isEmpty);
      expect(find.byType(CharacterEditConfirmationDialog), findsNothing);
      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );
}
