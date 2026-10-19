import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';
import 'package:teeq/features/feedback/domain/pending_feedback.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/home/presentation/widgets/call_start_button.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';

import '../../../../support/fake_home_repository.dart';
import '../../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<({Object error, bool blocking})> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add((error: error, blocking: blocking));
  }
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.email,
);

const _summary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
);

const _feedbackStubText = 'FEEDBACK-FLOW';
const _returnHomeButtonText = '홈으로 돌아가기';

const _pendingSummary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
  pendingFeedback: PendingFeedback(
    callSessionId: 'call-session-1',
    callIndex: 1,
  ),
);

({ProviderContainer container, _RecordingErrorHandler errorHandler}) _setUp(
  FakeHomeRepository repository,
) {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return (container: container, errorHandler: errorHandler);
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(body: SafeArea(child: HomeScreen())),
  ),
);

/// 홈 위에 피드백 흐름 자리표시 화면을 쌓을 수 있는 라우터 앱. 자리표시 화면은 `context.go`로 홈에 돌아온다.
GoRouter _pumpableRouter() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: SafeArea(child: HomeScreen())),
      ),
      GoRoute(
        path: AppRoutes.feedbackClosing,
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text(_feedbackStubText),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(_returnHomeButtonText),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

Future<GoRouter> _pumpRoutedHome(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = _pumpableRouter();
  await pumpAtViewport(
    tester,
    const ViewportCase(width: 393, height: 852, textScale: 1.0),
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

/// 명령형 push로 쌓인 위치까지 반영한 가장 위 경로.
String _currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _pumpHome(
  WidgetTester tester,
  ProviderContainer container, {
  ViewportCase viewport = const ViewportCase(
    width: 393,
    height: 852,
    textScale: 1.0,
  ),
}) => pumpAtViewport(tester, viewport, _app(container));

void main() {
  testWidgets('shows greeting name and tags', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    expect(find.text('소연아,\n오늘 하루 어땠어?'), findsOneWidget);
    expect(find.text('티티'), findsOneWidget);
    for (final tag in _summary.personalityTags) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.text('통화하기'), findsOneWidget);
    expect(find.text('캐릭터 수정'), findsOneWidget);
  });

  testWidgets('shows character name on a single line with ellipsis', (
    tester,
  ) async {
    final setUp = _setUp(
      FakeHomeRepository(
        summary: _summary.copyWith(characterName: '가나다라마바사아자차'),
      ),
    );
    await _pumpHome(
      tester,
      setUp.container,
      viewport: const ViewportCase(width: 320, height: 568, textScale: 1.2),
    );

    final nameText = tester.widget<Text>(find.text('가나다라마바사아자차'));
    expect(nameText.maxLines, 1);
    expect(nameText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing while loading', (tester) async {
    final gate = Completer<void>();
    final setUp = _setUp(FakeHomeRepository(summary: _summary, gate: gate));
    await _pumpHome(tester, setUp.container);
    // 응답이 오기 전에는 스피너 없이 비어 있다.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('통화하기'), findsNothing);
    expect(find.text('티티'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('티티'), findsOneWidget);
  });

  testWidgets('reports error with blocking true when load fails', (
    tester,
  ) async {
    final failure = Exception('load failed');
    final setUp = _setUp(FakeHomeRepository(error: failure));
    await _pumpHome(tester, setUp.container);

    expect(setUp.errorHandler.handledErrors, hasLength(1));
    expect(setUp.errorHandler.handledErrors.single.error, failure);
    expect(setUp.errorHandler.handledErrors.single.blocking, isTrue);
    expect(find.text('통화하기'), findsNothing);
  });

  testWidgets('reports refetch error with cached value as non-blocking', (
    tester,
  ) async {
    final failure = Exception('refetch failed');
    final setUp = _setUp(
      FakeHomeRepository(summary: _summary, errorAfterFirstFetch: failure),
    );
    await _pumpHome(tester, setUp.container);
    expect(setUp.errorHandler.handledErrors, isEmpty);

    setUp.container.invalidate(homeSummaryProvider(_member.memberId));
    await tester.pumpAndSettle();

    expect(setUp.errorHandler.handledErrors, hasLength(1));
    expect(setUp.errorHandler.handledErrors.single.error, failure);
    expect(setUp.errorHandler.handledErrors.single.blocking, isFalse);
    expect(find.text('통화하기'), findsOneWidget);
  });

  testWidgets('call button does nothing', (tester) async {
    final repository = FakeHomeRepository(summary: _summary);
    final setUp = _setUp(repository);
    await _pumpHome(tester, setUp.container);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(repository.fetchCount, 1);
    expect(setUp.errorHandler.handledErrors, isEmpty);
  });

  testWidgets('callButton_opensFeedbackFlowWhenPendingFeedbackExists', (
    tester,
  ) async {
    final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
    final router = await _pumpRoutedHome(tester, setUp.container);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();

    expect(_currentPath(router), '/calls/call-session-1/feedback');
    expect(find.text(_feedbackStubText), findsOneWidget);
  });

  testWidgets('callButton_doesNothingWhenNoPendingFeedback', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    final router = await _pumpRoutedHome(tester, setUp.container);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();

    expect(_currentPath(router), AppRoutes.home);
    expect(find.text(_feedbackStubText), findsNothing);
  });

  testWidgets('callButton_doubleTapPushesOnce', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
    final router = await _pumpRoutedHome(tester, setUp.container);

    // 프레임이 그려지기 전에 같은 탭 핸들러가 연달아 호출되는 상황을 만든다.
    final onPressed = tester
        .widget<CallStartButton>(find.byType(CallStartButton))
        .onPressed!;
    onPressed();
    onPressed();
    await tester.pumpAndSettle();
    expect(find.text(_feedbackStubText), findsOneWidget);

    // 한 번만 쌓였다면 한 번 pop으로 홈에 돌아온다.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text(_feedbackStubText), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('callButton_canOpenAgainAfterReturningHome', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
    await _pumpRoutedHome(tester, setUp.container);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();
    expect(find.text(_feedbackStubText), findsOneWidget);

    // 흐름은 pop이 아니라 go로 끝나므로 push의 Future가 끝나지 않을 수 있다.
    await tester.tap(find.text(_returnHomeButtonText));
    await tester.pumpAndSettle();
    expect(find.text(_feedbackStubText), findsNothing);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();
    expect(find.text(_feedbackStubText), findsOneWidget);
  });

  testWidgets('edit card opens edit confirmation dialog with character name', (
    tester,
  ) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    await tester.tap(find.byType(CharacterEditEntryCard));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('티티의 성향을 다시 설정할까?'), findsOneWidget);
  });

  testWidgets('double tap on edit card opens dialog once', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    // 프레임이 그려지기 전에 같은 탭 핸들러가 연달아 호출되는 상황을 만든다.
    final onTap = tester
        .widget<CharacterEditEntryCard>(find.byType(CharacterEditEntryCard))
        .onTap;
    onTap();
    onTap();
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('티티의 성향을 다시 설정할까?'), findsOneWidget);
  });

  testWidgets('edit dialog can reopen after closing', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    await tester.tap(find.byType(CharacterEditEntryCard));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byType(AppCloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byType(CharacterEditEntryCard));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets(
    'logout clears member so home renders nothing without error page',
    (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      await _pumpHome(tester, setUp.container);
      expect(find.text('티티'), findsOneWidget);

      setUp.container.read(currentMemberControllerProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(find.text('티티'), findsNothing);
      expect(find.text('통화하기'), findsNothing);
      expect(setUp.errorHandler.handledErrors, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('meets tap target guidelines at the default viewport', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('responsive layout', () {
    for (final viewport in viewportCases) {
      testWidgets('has no exception at ${viewport.label}', (tester) async {
        final longSummary = HomeSummary(
          characterName: '가나다라마바사아자차',
          personalityTags: ['가' * 50, '나' * 50, '다' * 50],
          greeting: List.filled(4, '가' * 45).join('\n'),
        );
        final setUp = _setUp(FakeHomeRepository(summary: longSummary));
        await _pumpHome(tester, setUp.container, viewport: viewport);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
