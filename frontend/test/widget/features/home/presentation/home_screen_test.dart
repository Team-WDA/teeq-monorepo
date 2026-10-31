import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/permission/microphone_permission_prompt.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';
import 'package:teeq/core/ui/progress/full_screen_loading_indicator.dart';
import 'package:teeq/features/feedback/domain/pending_feedback.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_repository.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/home/presentation/widgets/call_start_button.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/fake_app_permission_gateway.dart';
import '../../../../support/fake_home_repository.dart';
import '../../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<({Object error, bool blocking})> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add((error: error, blocking: blocking));
  }
}

/// 테스트 도중 돌려줄 홈 요약을 바꿀 수 있는 홈 저장소.
class _SwitchableHomeRepository implements HomeRepository {
  _SwitchableHomeRepository(this.summary);

  HomeSummary summary;

  @override
  Future<HomeSummary> fetchHome() async => summary;
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _summary = HomeSummary(
  characterName: '티티',
  characterType: CharacterType.character1,
  characterMood: CharacterMood.welcome,
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
);

const _feedbackStubText = 'FEEDBACK-FLOW';
const _callStubText = 'CALL-SCREEN';
const _returnHomeButtonText = '홈으로 돌아가기';
const _closeButtonText = '닫기';

/// 피드백·통화 흐름 자리표시 화면. 뒤로가기(pop)와 `context.go` 홈 복귀를 모두 제공한다.
Widget _flowStubScreen(BuildContext context, String text) => Scaffold(
  body: Column(
    children: [
      Text(text),
      TextButton(
        onPressed: () => context.pop(),
        child: const Text(_closeButtonText),
      ),
      TextButton(
        onPressed: () => context.go(AppRoutes.home),
        child: const Text(_returnHomeButtonText),
      ),
    ],
  ),
);

/// 피드백·통화 흐름 자리표시 라우트.
List<GoRoute> _flowStubRoutes() => [
  GoRoute(
    path: AppRoutes.feedbackClosing,
    builder: (context, state) => _flowStubScreen(context, _feedbackStubText),
  ),
  GoRoute(
    path: AppRoutes.call,
    builder: (context, state) => _flowStubScreen(context, _callStubText),
  ),
];

const _pendingSummary = HomeSummary(
  characterName: '티티',
  characterType: CharacterType.character1,
  characterMood: CharacterMood.welcome,
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
  pendingFeedback: PendingFeedback(
    callSessionId: 'call-session-1',
    callIndex: 1,
  ),
);

({
  ProviderContainer container,
  _RecordingErrorHandler errorHandler,
  FakeMicrophonePermissionPrompt microphonePermissionPrompt,
})
_setUp(HomeRepository repository) {
  final errorHandler = _RecordingErrorHandler();
  final microphonePermissionPrompt = FakeMicrophonePermissionPrompt();
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
      microphonePermissionPromptProvider.overrideWithValue(
        microphonePermissionPrompt,
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return (
    container: container,
    errorHandler: errorHandler,
    microphonePermissionPrompt: microphonePermissionPrompt,
  );
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(body: SafeArea(child: HomeScreen())),
  ),
);

/// 홈 위에 피드백·통화 흐름 자리표시 화면을 쌓을 수 있는 라우터 앱.
GoRouter _pumpableRouter() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: SafeArea(child: HomeScreen())),
      ),
      ..._flowStubRoutes(),
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

const _otherTabText = 'OTHER-TAB';
const _otherTabPath = '/other';

/// 홈 탭과 다른 탭을 가진 라우터. 탭 전환은 `goBranch`로 한다. 흐름 화면은 실제 앱처럼 셸 바깥에 둔다.
GoRouter _tabbedRouter() {
  final router = GoRouter(
    routes: [
      ..._flowStubRoutes(),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => Scaffold(
          body: Column(
            children: [
              Expanded(child: navigationShell),
              TextButton(
                onPressed: () => navigationShell.goBranch(0),
                child: const Text('tab-home'),
              ),
              TextButton(
                onPressed: () => navigationShell.goBranch(1),
                child: const Text('tab-other'),
              ),
            ],
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) =>
                    const SafeArea(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'pushed',
                    builder: (context, state) =>
                        const Scaffold(body: Text('PUSHED')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _otherTabPath,
                builder: (context, state) => const Text(_otherTabText),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

Future<GoRouter> _pumpTabbedHome(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = _tabbedRouter();
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

  testWidgets('첫_진입은_로딩_표시_뒤_본문을_그린다', (tester) async {
    final gate = Completer<void>();
    final setUp = _setUp(FakeHomeRepository(summary: _summary, gate: gate));
    // 스피너가 계속 도는 동안에는 pumpAndSettle이 끝나지 않으므로 직접 pump한다.
    await tester.pumpWidget(_app(setUp.container));
    await tester.pump();

    expect(find.byType(FullScreenLoadingIndicator), findsOneWidget);
    expect(find.text('통화하기'), findsNothing);
    expect(find.text('티티'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenLoadingIndicator), findsNothing);
    expect(find.text('티티'), findsOneWidget);
  });

  group('재진입 재조회', () {
    testWidgets('다른_탭에_갔다_홈_탭으로_돌아오면_다시_조회하고_그동안_로딩을_보인다', (tester) async {
      final gate = Completer<void>();
      final repository = FakeHomeRepository(summary: _summary);
      final setUp = _setUp(repository);
      await _pumpTabbedHome(tester, setUp.container);
      expect(repository.fetchCount, 1);

      await tester.tap(find.text('tab-other'));
      await tester.pumpAndSettle();
      expect(find.text(_otherTabText), findsOneWidget);
      expect(repository.fetchCount, 1);

      repository.gate = gate;
      await tester.tap(find.text('tab-home'));
      await tester.pump();
      await tester.pump();

      expect(repository.fetchCount, 2);
      expect(find.byType(FullScreenLoadingIndicator), findsOneWidget);
      expect(find.text('소연아,\n오늘 하루 어땠어?'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('소연아,\n오늘 하루 어땠어?'), findsOneWidget);
    });

    testWidgets('홈_위에_올린_화면에서_돌아오면_다시_조회한다', (tester) async {
      final repository = FakeHomeRepository(summary: _summary);
      final setUp = _setUp(repository);
      final router = await _pumpTabbedHome(tester, setUp.container);

      unawaited(router.push<void>('/pushed'));
      await tester.pumpAndSettle();
      expect(find.text('PUSHED'), findsOneWidget);
      expect(repository.fetchCount, 1);

      router.pop();
      await tester.pumpAndSettle();

      expect(repository.fetchCount, 2);
    });

    testWidgets('홈_탭_재탭은_다시_조회하지_않는다', (tester) async {
      final repository = FakeHomeRepository(summary: _summary);
      final setUp = _setUp(repository);
      await _pumpTabbedHome(tester, setUp.container);

      await tester.tap(find.text('tab-home'));
      await tester.pumpAndSettle();

      expect(repository.fetchCount, 1);
    });

    testWidgets('이미_재조회_중이면_복귀해도_중복_조회하지_않는다', (tester) async {
      final repository = FakeHomeRepository(summary: _summary);
      final setUp = _setUp(repository);
      await _pumpTabbedHome(tester, setUp.container);

      await tester.tap(find.text('tab-other'));
      await tester.pumpAndSettle();
      repository.gate = Completer<void>();
      setUp.container.invalidate(homeSummaryProvider(_member.memberId));
      await tester.pump();
      expect(repository.fetchCount, 2);

      await tester.tap(find.text('tab-home'));
      await tester.pump();

      expect(repository.fetchCount, 2);
    });

    testWidgets('재조회가_실패하면_이전_본문을_유지한다', (tester) async {
      final failure = Exception('refetch failed');
      final repository = FakeHomeRepository(
        summary: _summary,
        errorAfterFirstFetch: failure,
      );
      final setUp = _setUp(repository);
      await _pumpTabbedHome(tester, setUp.container);

      await tester.tap(find.text('tab-other'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('tab-home'));
      await tester.pumpAndSettle();

      expect(repository.fetchCount, 2);
      expect(find.byType(FullScreenLoadingIndicator), findsNothing);
      expect(find.text('소연아,\n오늘 하루 어땠어?'), findsOneWidget);
      expect(setUp.errorHandler.handledErrors, hasLength(1));
      expect(setUp.errorHandler.handledErrors.single.error, failure);
      expect(setUp.errorHandler.handledErrors.single.blocking, isFalse);
    });
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

  group('통화하기 버튼', () {
    testWidgets('대기_피드백이_없으면_통화_화면으로_이동한다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      final router = await _pumpRoutedHome(tester, setUp.container);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppRoutes.call);
      expect(find.text(_callStubText), findsOneWidget);
    });

    testWidgets('대기_피드백이_있어도_통화_화면으로_이동한다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpRoutedHome(tester, setUp.container);
      // 자동으로 열린 피드백 흐름을 닫고 홈으로 돌아온다.
      await tester.tap(find.text(_closeButtonText));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.home);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppRoutes.call);
      expect(find.text(_callStubText), findsOneWidget);
      expect(find.text(_feedbackStubText), findsNothing);
    });

    testWidgets('연타해도_한_번만_이동한다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      final router = await _pumpRoutedHome(tester, setUp.container);

      // 프레임이 그려지기 전에 같은 탭 핸들러가 연달아 호출되는 상황을 만든다.
      final onPressed = tester
          .widget<CallStartButton>(find.byType(CallStartButton))
          .onPressed!;
      onPressed();
      onPressed();
      await tester.pumpAndSettle();
      expect(find.text(_callStubText), findsOneWidget);

      // 한 번만 쌓였다면 한 번 pop으로 홈에 돌아온다.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text(_callStubText), findsNothing);
      expect(_currentPath(router), AppRoutes.home);
    });

    testWidgets('통화_화면에서_홈으로_돌아오면_다시_이동할_수_있다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      await _pumpRoutedHome(tester, setUp.container);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      expect(find.text(_callStubText), findsOneWidget);

      // 흐름은 pop이 아니라 go로 끝나므로 push의 Future가 끝나지 않을 수 있다.
      await tester.tap(find.text(_returnHomeButtonText));
      await tester.pumpAndSettle();
      expect(find.text(_callStubText), findsNothing);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      expect(find.text(_callStubText), findsOneWidget);
    });
  });

  group('대기 피드백 자동 열림', () {
    testWidgets('홈이_현재_화면이고_대기_피드백이_있으면_한_번만_연다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpRoutedHome(tester, setUp.container);

      expect(_currentPath(router), '/calls/call-session-1/feedback');
      expect(find.text(_feedbackStubText), findsOneWidget);
      // 첫 프레임과 데이터 도착 두 계기가 겹쳐도 한 번만 쌓였다면 한 번 pop으로 홈에 돌아온다.
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));
    });

    testWidgets('피드백_흐름을_닫고_돌아오면_같은_피드백을_다시_열지_않는다', (tester) async {
      final repository = FakeHomeRepository(summary: _pendingSummary);
      final setUp = _setUp(repository);
      final router = await _pumpRoutedHome(tester, setUp.container);
      expect(find.text(_feedbackStubText), findsOneWidget);

      await tester.tap(find.text(_closeButtonText));
      await tester.pumpAndSettle();

      // 홈으로 돌아와 다시 조회한 요약에도 대기 피드백이 있지만 열지 않는다.
      expect(repository.fetchCount, 2);
      expect(_currentPath(router), AppRoutes.home);
      expect(find.text(_feedbackStubText), findsNothing);
    });

    testWidgets('go로_피드백_흐름을_끝내고_돌아와도_같은_피드백을_다시_열지_않는다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpRoutedHome(tester, setUp.container);

      await tester.tap(find.text(_returnHomeButtonText));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppRoutes.home);
      expect(find.text(_feedbackStubText), findsNothing);
    });

    testWidgets('통화_화면에서_홈으로_돌아오면_대기_피드백을_다시_연다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpRoutedHome(tester, setUp.container);
      await tester.tap(find.text(_closeButtonText));
      await tester.pumpAndSettle();
      expect(find.text(_feedbackStubText), findsNothing);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_returnHomeButtonText));
      await tester.pumpAndSettle();

      expect(_currentPath(router), '/calls/call-session-1/feedback');
      expect(find.text(_feedbackStubText), findsOneWidget);
    });

    testWidgets('다른_탭에_갔다_홈_탭으로_돌아오면_대기_피드백을_다시_연다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpTabbedHome(tester, setUp.container);
      expect(find.text(_feedbackStubText), findsOneWidget);
      await tester.tap(find.text(_closeButtonText));
      await tester.pumpAndSettle();
      expect(find.text(_feedbackStubText), findsNothing);

      await tester.tap(find.text('tab-other'));
      await tester.pumpAndSettle();
      // 다른 탭에 있는 동안에는 열지 않는다.
      expect(find.text(_feedbackStubText), findsNothing);
      expect(find.text(_otherTabText), findsOneWidget);

      await tester.tap(find.text('tab-home'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), '/calls/call-session-1/feedback');
      expect(find.text(_feedbackStubText), findsOneWidget);
    });

    testWidgets('캐릭터_수정_팝업이_떠_있으면_대기_피드백을_열지_않는다', (tester) async {
      final repository = _SwitchableHomeRepository(_summary);
      final setUp = _setUp(repository);
      final router = await _pumpTabbedHome(tester, setUp.container);
      await tester.tap(find.byType(CharacterEditEntryCard));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // 팝업이 떠 있는 동안 대기 피드백이 생긴 요약이 도착한다.
      repository.summary = _pendingSummary;
      setUp.container.invalidate(homeSummaryProvider(_member.memberId));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppRoutes.home);
      expect(find.text(_feedbackStubText), findsNothing);
    });

    testWidgets('라우터가_없으면_이동하지_않고_오류도_없다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      await _pumpHome(tester, setUp.container);

      expect(find.text('통화하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(setUp.errorHandler.handledErrors, isEmpty);
    });
  });

  group('탭 셸 안의 홈', () {
    testWidgets('통화_화면에서_go로_돌아오면_통화하기가_다시_이동한다', (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      final router = await _pumpTabbedHome(tester, setUp.container);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.call);

      await tester.tap(find.text(_returnHomeButtonText));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.home);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.call);
      expect(find.text(_callStubText), findsOneWidget);
    });

    testWidgets('자동으로_연_피드백을_go로_끝내면_잠금이_풀리고_같은_피드백은_다시_열지_않는다', (
      tester,
    ) async {
      final setUp = _setUp(FakeHomeRepository(summary: _pendingSummary));
      final router = await _pumpTabbedHome(tester, setUp.container);
      expect(find.text(_feedbackStubText), findsOneWidget);

      await tester.tap(find.text(_returnHomeButtonText));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.home);
      expect(find.text(_feedbackStubText), findsNothing);

      await tester.tap(find.text('통화하기'));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppRoutes.call);
      expect(find.text(_callStubText), findsOneWidget);
    });
  });

  testWidgets('홈_첫_표시에서_마이크_권한을_한_번_요청한다', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);
    expect(setUp.microphonePermissionPrompt.requestOnceCount, 1);

    // 홈 요약을 다시 조회해 다시 그려도 더 요청하지 않는다.
    setUp.container.invalidate(homeSummaryProvider(_member.memberId));
    await tester.pumpAndSettle();
    expect(setUp.microphonePermissionPrompt.requestOnceCount, 1);
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
          characterType: CharacterType.character1,
          characterMood: CharacterMood.welcome,
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
