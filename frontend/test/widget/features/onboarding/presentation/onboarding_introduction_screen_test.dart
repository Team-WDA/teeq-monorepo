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
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _startButtonLabel = '나만의 티크 만들기';

Future<ProviderContainer> _pumpRoutedScreen(
  WidgetTester tester, {
  required FakeOnboardingCatalogRepository catalogRepository,
  ErrorHandler? errorHandler,
}) async {
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
  final container = ProviderContainer(
    // 앱과 같은 재시도 정책을 써서 예상 밖 오류가 자동 재시도되지 않게 한다.
    retry: providerRetry,
    overrides: [
      onboardingCatalogRepositoryProvider.overrideWithValue(catalogRepository),
      if (errorHandler != null)
        errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

bool _isStartButtonLoading(WidgetTester tester) => tester
    .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
    .isLoading;

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
    expect(find.text(_startButtonLabel), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });

  testWidgets(
    'tapping start button starts first-time flow and opens question screen',
    (tester) async {
      final container = await _pumpRoutedScreen(
        tester,
        catalogRepository: FakeOnboardingCatalogRepository(),
      );
      final relationship = testOnboardingQuestion('RELATIONSHIP');
      container.read(characterSetupFlowControllerProvider.notifier)
        ..start(CharacterSetupMode.edit)
        ..toggleOption(relationship, relationship.options.first);

      await tester.tap(find.text(_startButtonLabel));
      await tester.pumpAndSettle();

      expect(find.text('질문 스텁'), findsOneWidget);
      final state = container.read(characterSetupFlowControllerProvider);
      expect(state.mode, CharacterSetupMode.firstTime);
      expect(state.selections.selectedFor(relationship), isEmpty);
    },
  );

  testWidgets(
    'start button is loading while catalog loads and navigates after it completes',
    (tester) async {
      final gate = Completer<void>();
      final catalogRepository = FakeOnboardingCatalogRepository(gate: gate);
      await _pumpRoutedScreen(tester, catalogRepository: catalogRepository);

      await tester.tap(find.text(_startButtonLabel));
      await tester.pump();

      expect(_isStartButtonLoading(tester), isTrue);
      expect(find.text('질문 스텁'), findsNothing);

      // 대기 중 다시 탭해도 재진입하지 않는다.
      await tester.tap(find.byType(PrimaryFilledButton));
      await tester.pump();
      expect(catalogRepository.fetchCount, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );

  testWidgets(
    'catalog failure reports error stays on screen and retry refetches',
    (tester) async {
      final failure = UnexpectedException(StateError('카탈로그 실패'));
      final errorHandler = _RecordingErrorHandler();
      final catalogRepository = FakeOnboardingCatalogRepository(
        firstFetchError: failure,
      );
      await _pumpRoutedScreen(
        tester,
        catalogRepository: catalogRepository,
        errorHandler: errorHandler,
      );

      await tester.tap(find.text(_startButtonLabel));
      await tester.pumpAndSettle();

      expect(errorHandler.handledErrors, [failure]);
      expect(find.text('질문 스텁'), findsNothing);
      expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
      expect(_isStartButtonLoading(tester), isFalse);

      await tester.tap(find.text(_startButtonLabel));
      await tester.pumpAndSettle();

      expect(catalogRepository.fetchCount, 2);
      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );

  testWidgets(
    'cached catalog error left by a dismissed entry is refetched on next tap',
    (tester) async {
      final failure = UnexpectedException(StateError('카탈로그 실패'));
      final errorHandler = _RecordingErrorHandler();
      final catalogRepository = FakeOnboardingCatalogRepository(
        firstFetchError: failure,
      );
      final container = await _pumpRoutedScreen(
        tester,
        catalogRepository: catalogRepository,
        errorHandler: errorHandler,
      );
      // 이전 진입이 실패한 채 사라져 invalidate하지 못한 상황을 만든다.
      container.read(onboardingCatalogProvider.future).ignore();
      await tester.pump();
      expect(container.read(onboardingCatalogProvider).hasError, isTrue);

      await tester.tap(find.text(_startButtonLabel));
      await tester.pumpAndSettle();

      expect(catalogRepository.fetchCount, 2);
      expect(errorHandler.handledErrors, isEmpty);
      expect(find.text('질문 스텁'), findsOneWidget);
    },
  );
}
