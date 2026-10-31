import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/permission_handler_gateway.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/call/data/call_repository_impl.dart';
import 'package:teeq/features/call/data/foreground_call_keep_alive.dart';
import 'package:teeq/features/call/data/livekit_call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_event_message.dart';
import 'package:teeq/features/call/domain/call_limit_status.dart';
import 'package:teeq/features/call/domain/call_room_event.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';
import 'package:teeq/features/call/domain/call_termination.dart';
import 'package:teeq/features/call/presentation/call_screen.dart';
import 'package:teeq/features/call/presentation/call_timing_provider.dart';
import 'package:teeq/features/call/presentation/widgets/call_back_arrow_button.dart';
import 'package:teeq/features/call/presentation/widgets/call_controls_bar.dart';
import 'package:teeq/features/call/presentation/widgets/call_limit_info_chip.dart';
import 'package:teeq/features/call/presentation/widgets/call_slide_to_answer.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../support/fake_app_permission_gateway.dart';
import '../../../support/fake_call_keep_alive.dart';
import '../../../support/fake_call_repository.dart';
import '../../../support/fake_call_room_gateway.dart';
import '../../../support/fake_current_member_controller.dart';
import '../../../support/fake_home_repository.dart';
import '../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _homeText = 'HOME';
const _feedbackText = 'FEEDBACK-FLOW';
const _slideLabel = '밀어서 통화하기';

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
  greeting: '안녕',
);

const _startInfo = CallStartInfo(
  callSessionId: 'call-1',
  maxDurationSeconds: 600,
  serverUrl: 'wss://livekit.example.com',
  accessToken: 'token',
);

final _startTime = DateTime.utc(2026, 11, 1, 12);

class _CallScreenHarness {
  _CallScreenHarness({
    required this.tester,
    required this.gateway,
    required this.errorHandler,
    required this.router,
  });

  final WidgetTester tester;
  final GoRouter router;
  final FakeCallRoomGateway gateway;
  final _RecordingErrorHandler errorHandler;

  /// 가짜 시계의 현재 시각. 테스트가 직접 앞당긴다.
  DateTime now = _startTime;

  Future<void> emit(CallRoomEvent event) async {
    gateway.emit(event);
    // 이벤트는 마이크로태스크로 전달되고, 상태 변경이 다음 프레임에 그려진다.
    await tester.pump();
    await tester.pump();
  }

  Future<void> emitEventMessage(Map<String, Object?> json) => emit(
    CallRoomDataReceived(
      topic: callEventTopic,
      payload: utf8.encode(jsonEncode(json)),
    ),
  );

  /// 슬라이더 손잡이를 끝까지 밀어 전화를 받는다.
  Future<void> slideToAnswer() async {
    final slider = find.byType(CallSlideToAnswer);
    final handleCenter =
        tester.getTopLeft(slider) +
        Offset(
          tester.getSize(slider).height / 2,
          tester.getSize(slider).height / 2,
        );
    await tester.dragFrom(handleCenter, const Offset(500, 0));
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapText(String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// 통화 화면을 떠나 컨트롤러와 타이머를 정리한다(실제로 화면을 벗어날 때와 같다).
  Future<void> tearDownScreen() async {
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
  }
}

Future<_CallScreenHarness> _pumpCallScreen(
  WidgetTester tester, {
  FakeCallRepository? repository,
  FakeCallRoomGateway? gateway,
  FakeAppPermissionGateway? permissionGateway,
  ViewportCase viewport = const ViewportCase(
    width: 393,
    height: 852,
    textScale: 1.0,
  ),
}) async {
  final roomGateway = gateway ?? FakeCallRoomGateway();
  final errorHandler = _RecordingErrorHandler();
  late final _CallScreenHarness harness;
  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      callRepositoryProvider.overrideWithValue(
        repository ?? FakeCallRepository(startInfo: _startInfo),
      ),
      callRoomGatewayProvider.overrideWithValue(roomGateway),
      appPermissionGatewayProvider.overrideWithValue(
        permissionGateway ??
            FakeAppPermissionGateway(
              initialStatus: AppPermissionStatus.granted,
            ),
      ),
      callKeepAliveProvider.overrideWithValue(FakeCallKeepAlive()),
      callClockProvider.overrideWithValue(() => harness.now),
      errorHandlerProvider.overrideWithValue(errorHandler),
      homeRepositoryProvider.overrideWithValue(
        FakeHomeRepository(summary: _summary),
      ),
      currentMemberControllerProvider.overrideWith(
        () => FakeCurrentMemberController(_member),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text(_homeText)),
      ),
      GoRoute(
        path: AppRoutes.call,
        builder: (context, state) => const CallScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedbackClosing,
        builder: (context, state) => const Scaffold(body: Text(_feedbackText)),
      ),
    ],
  );
  addTearDown(router.dispose);
  harness = _CallScreenHarness(
    tester: tester,
    gateway: roomGateway,
    errorHandler: errorHandler,
    router: router,
  );
  await pumpAtViewport(
    tester,
    viewport,
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  // 홈에서 통화 화면을 여는 실제 흐름처럼 push한다.
  router.push(AppRoutes.call);
  await tester.pumpAndSettle();
  return harness;
}

/// 첫 권한 요청은 예외를 던지고, 그 뒤 요청은 허용으로 답하는 권한 게이트웨이.
class _ThrowsOnFirstRequestPermissionGateway extends FakeAppPermissionGateway {
  _ThrowsOnFirstRequestPermissionGateway();

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    requestCount += 1;
    if (requestCount == 1) {
      throw StateError('permission request failed');
    }
    return super.request(permission);
  }
}

/// 오늘 남은 통화 시간 조회를 테스트가 완료할 때까지 붙잡아 두는 저장소.
class _HeldLimitStatusCallRepository extends FakeCallRepository {
  _HeldLimitStatusCallRepository() : super(startInfo: _startInfo);

  final Completer<CallLimitStatus> limitStatusCompleter =
      Completer<CallLimitStatus>();

  @override
  Future<CallLimitStatus> fetchTodayLimitStatus() =>
      limitStatusCompleter.future;
}

void main() {
  testWidgets('울리는 중에는 슬라이더가 보이고 뒤로가기는 거절로 홈에 간다', (tester) async {
    final harness = await _pumpCallScreen(tester);

    expect(find.text('TeeQ'), findsOneWidget);
    expect(find.text('티티'), findsOneWidget);
    expect(find.text(_slideLabel), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_homeText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('화면의 뒤로가기 화살표도 거절로 홈에 간다', (tester) async {
    final harness = await _pumpCallScreen(tester);

    await tester.tap(find.byType(CallBackArrowButton));
    await tester.pumpAndSettle();

    expect(find.text(_homeText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('권한이 거절되면 권한 카드를 보이고 "나중에 하기"는 홈으로 간다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      permissionGateway: FakeAppPermissionGateway(
        requestResult: AppPermissionStatus.denied,
      ),
    );

    await harness.slideToAnswer();

    expect(find.text('연결 실패'), findsOneWidget);
    expect(find.text('마이크 권한이 필요해'), findsOneWidget);
    expect(find.text('티티와 대화를 시작하려면 마이크 권한을 허용해야 돼.'), findsOneWidget);
    expect(find.text('권한 허용하기'), findsOneWidget);

    await harness.tapText('나중에 하기');

    expect(find.text(_homeText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('통화중에는 경과 시간과 컨트롤을 보이고, 종료 확인 뒤 피드백으로 간다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
    );
    await harness.slideToAnswer();
    expect(find.text('00:00'), findsOneWidget);

    harness.now = _startTime.add(const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:12'), findsOneWidget);
    expect(find.byType(CallControlsBar), findsOneWidget);
    expect(find.text('스피커'), findsOneWidget);
    expect(find.text('종료'), findsOneWidget);
    expect(find.text('음소거'), findsOneWidget);

    await tester.tap(find.text('종료'));
    await tester.pump();
    expect(find.text('통화를 마칠까?'), findsOneWidget);

    await tester.tap(find.text('계속 통화하기'));
    await tester.pump();
    expect(find.text('통화를 마칠까?'), findsNothing);

    await tester.tap(find.text('종료'));
    await tester.pump();
    await harness.tapText('통화 마치기');

    expect(find.text(_feedbackText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('통화중 하드웨어 뒤로가기는 종료 확인 카드를 열고, 한 번 더 누르면 닫는다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
    );
    await harness.slideToAnswer();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.text('통화를 마칠까?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.text('통화를 마칠까?'), findsNothing);
    await harness.tearDownScreen();
  });

  testWidgets('워커가 들어오기 전 연결중에 끝내면 확인 없이 홈으로 간다', (tester) async {
    final harness = await _pumpCallScreen(tester);
    await harness.slideToAnswer();
    expect(find.text('연결중'), findsOneWidget);

    await tester.tap(find.text('종료'));
    await tester.pump();

    expect(find.text('통화를 마칠까?'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(_homeText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('곧 종료 메시지를 받으면 카드를 보이고 "계속 이야기하기"로 닫는다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
    );
    await harness.slideToAnswer();

    await harness.emitEventMessage({
      'type': 'CALL_ENDING_SOON',
      'v': 1,
      'remainingSeconds': 60,
    });

    expect(find.text('통화 시간이 곧 끝나가.'), findsOneWidget);
    expect(find.text('지금 마치기'), findsOneWidget);

    await tester.tap(find.text('계속 이야기하기'));
    await tester.pump();

    expect(find.text('통화 시간이 곧 끝나가.'), findsNothing);
    await harness.tearDownScreen();
  });

  testWidgets('통화 시작이 하루 한도로 거절되면 "홈으로 돌아가기" 버튼 하나만 보인다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      repository: FakeCallRepository(
        startError: ApiException(
          errorCode: ErrorCode.callLimitInsufficient,
          httpStatus: 403,
        ),
      ),
    );
    await harness.slideToAnswer();

    expect(find.text('오늘 통화 시간이 다 됐어'), findsOneWidget);
    expect(find.text('홈으로 돌아가기'), findsOneWidget);
    expect(find.text('피드백 남기기'), findsNothing);

    await harness.tapText('홈으로 돌아가기');

    expect(find.text(_homeText), findsOneWidget);
    expect(harness.errorHandler.handledErrors, isEmpty);
    await harness.tearDownScreen();
  });

  group('통화 도중 한도로 방이 닫히면', () {
    Future<_CallScreenHarness> endByLimit(
      WidgetTester tester,
      String limitKind, {
      FakeCallRepository? repository,
      bool settle = true,
    }) async {
      final harness = await _pumpCallScreen(
        tester,
        repository: repository,
        gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
      );
      await harness.slideToAnswer();
      await harness.emitEventMessage({
        'type': 'CALL_LIMIT_REACHED',
        'v': 1,
        'limitKind': limitKind,
      });
      await harness.emit(
        const CallRoomMetadataChanged('{"v":1,"end_reason":"limit_reached"}'),
      );
      await harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.roomDeleted),
      );
      // 한도 화면에서는 타이머가 멈추므로 남은 조회 결과까지 그린다.
      if (settle) {
        await tester.pumpAndSettle();
      }
      return harness;
    }

    testWidgets('per_day 칩을 보이고 "피드백 남기기"는 피드백으로 간다', (tester) async {
      final harness = await endByLimit(tester, 'PER_DAY');

      expect(find.text('통화 종료'), findsOneWidget);
      expect(find.text('오늘 통화 시간이 다 됐어'), findsOneWidget);
      final chip = tester.widget<CallLimitInfoChip>(
        find.byType(CallLimitInfoChip),
      );
      expect(chip.emphasizedText, '24:00');
      expect(find.textContaining('24:00', findRichText: true), findsOneWidget);

      await harness.tapText('피드백 남기기');

      expect(find.text(_feedbackText), findsOneWidget);
      await harness.tearDownScreen();
    });

    testWidgets('per_call 칩은 오늘 남은 시간을 분으로 보인다', (tester) async {
      final harness = await endByLimit(
        tester,
        'PER_CALL',
        repository: FakeCallRepository(
          startInfo: _startInfo,
          limitStatus: const CallLimitStatus(remainingSeconds: 720),
        ),
      );

      expect(find.text('이번 통화 시간이 다 됐어'), findsOneWidget);
      expect(find.textContaining('12분', findRichText: true), findsOneWidget);
      expect(find.text('다시 통화하기'), findsOneWidget);
      await harness.tearDownScreen();
    });

    testWidgets('per_call 조회 중에는 칩 자리만 비워 두고, 끝나면 남은 시간을 보인다', (tester) async {
      final repository = _HeldLimitStatusCallRepository();
      final harness = await endByLimit(
        tester,
        'PER_CALL',
        repository: repository,
        settle: false,
      );
      await tester.pump();

      expect(find.text('이번 통화 시간이 다 됐어'), findsOneWidget);
      expect(find.byType(CallLimitInfoChip), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == AppLayout.callLimitInfoChipHeight &&
              widget.child == null,
        ),
        findsOneWidget,
      );

      repository.limitStatusCompleter.complete(
        const CallLimitStatus(remainingSeconds: 720),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('12분', findRichText: true), findsOneWidget);
      await harness.tearDownScreen();
    });

    testWidgets('per_call 조회가 실패하면 칩을 숨기고 에러를 알리지 않는다', (tester) async {
      final harness = await endByLimit(
        tester,
        'PER_CALL',
        repository: FakeCallRepository(
          startInfo: _startInfo,
          limitError: StateError('limit fetch failed'),
        ),
      );

      expect(find.text('이번 통화 시간이 다 됐어'), findsOneWidget);
      expect(find.byType(CallLimitInfoChip), findsNothing);
      expect(harness.errorHandler.handledErrors, isEmpty);
      await harness.tearDownScreen();
    });

    testWidgets('per_call "다시 통화하기"는 같은 화면을 울리는 중으로 되돌리고 다시 받으면 새 통화를 시작한다', (
      tester,
    ) async {
      final repository = FakeCallRepository(
        startInfo: _startInfo,
        limitStatus: const CallLimitStatus(remainingSeconds: 720),
      );
      final harness = await endByLimit(
        tester,
        'PER_CALL',
        repository: repository,
      );
      expect(repository.startCallCount, 1);

      await harness.tapText('다시 통화하기');

      expect(find.text(_slideLabel), findsOneWidget);
      expect(find.text('TeeQ'), findsOneWidget);
      expect(find.text('이번 통화 시간이 다 됐어'), findsNothing);

      await harness.slideToAnswer();
      await tester.pump();

      expect(repository.startCallCount, 2);
      expect(harness.gateway.connectCount, 2);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(CallControlsBar), findsOneWidget);
      await harness.tearDownScreen();
    });
  });

  testWidgets('방 연결에 실패하면 연결 실패 카드와 "다시 연결하기"를 보인다', (tester) async {
    final harness = await _pumpCallScreen(
      tester,
      gateway: FakeCallRoomGateway(connectError: StateError('connect failed')),
    );
    await harness.slideToAnswer();

    expect(find.text('연결하지 못했어'), findsOneWidget);
    expect(find.text('다시 연결하기'), findsOneWidget);
    expect(find.text('홈으로 돌아가기'), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('받기가 실패해 울리는 화면으로 돌아오면 슬라이더가 처음 자리로 돌아가 다시 받을 수 있다', (
    tester,
  ) async {
    final repository = FakeCallRepository(startInfo: _startInfo);
    final harness = await _pumpCallScreen(
      tester,
      repository: repository,
      permissionGateway: _ThrowsOnFirstRequestPermissionGateway(),
    );

    await harness.slideToAnswer();

    expect(find.text(_slideLabel), findsOneWidget);
    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(repository.startCallCount, 0);

    // 손잡이가 끝에 남아 있으면 처음 자리에서 시작한 끌기가 손잡이에 닿지 않는다.
    await harness.slideToAnswer();

    expect(repository.startCallCount, 1);
    expect(find.text('연결중'), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('통화 시작 전 연결 시간 초과 카드의 보조 버튼은 "홈으로 돌아가기"다', (tester) async {
    final harness = await _pumpCallScreen(tester);
    await harness.slideToAnswer();

    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.text('연결이 지연되고 있어'), findsOneWidget);
    expect(find.text('홈으로 돌아가기'), findsOneWidget);
    expect(find.text('통화 마치기'), findsNothing);

    await harness.tapText('홈으로 돌아가기');
    expect(find.text(_homeText), findsOneWidget);
    await harness.tearDownScreen();
  });

  testWidgets('통화 시작 뒤 연결 시간 초과 카드의 보조 버튼은 "통화 마치기"이고 피드백으로 간다', (
    tester,
  ) async {
    final harness = await _pumpCallScreen(
      tester,
      gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
    );
    await harness.slideToAnswer();
    await harness.emit(
      const CallRoomDisconnected(CallDisconnectCause.connectionLost),
    );
    expect(find.text('연결이 잠시 끊겼어'), findsOneWidget);

    // 재접속은 되지만 워커가 다시 보이지 않아 대기 시간이 지난다.
    await tester.tap(find.text('다시 연결하기'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.text('연결이 지연되고 있어'), findsOneWidget);
    expect(find.text('통화 마치기'), findsOneWidget);
    expect(find.text('홈으로 돌아가기'), findsNothing);

    await harness.tapText('통화 마치기');
    expect(find.text(_feedbackText), findsOneWidget);
    await harness.tearDownScreen();
  });

  group('좁은 화면(320, 글자 배율 1.2)에서 넘침이 없다', () {
    const narrowViewport = ViewportCase(
      width: 320,
      height: 568,
      textScale: 1.2,
    );

    testWidgets('울리는 중', (tester) async {
      final harness = await _pumpCallScreen(tester, viewport: narrowViewport);

      expect(find.text(_slideLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
      await harness.tearDownScreen();
    });

    testWidgets('통화중과 종료 확인 카드', (tester) async {
      final harness = await _pumpCallScreen(
        tester,
        viewport: narrowViewport,
        gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
      );
      await harness.slideToAnswer();

      expect(find.byType(CallControlsBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('종료'));
      await tester.pump();

      expect(find.text('통화를 마칠까?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await harness.tearDownScreen();
    });

    testWidgets('권한 카드', (tester) async {
      final harness = await _pumpCallScreen(
        tester,
        viewport: narrowViewport,
        permissionGateway: FakeAppPermissionGateway(
          requestResult: AppPermissionStatus.denied,
        ),
      );
      await harness.slideToAnswer();

      expect(find.text('마이크 권한이 필요해'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await harness.tearDownScreen();
    });

    testWidgets('per_call 한도 카드(칩과 버튼 두 개)', (tester) async {
      final harness = await _pumpCallScreen(
        tester,
        viewport: narrowViewport,
        repository: FakeCallRepository(
          startInfo: _startInfo,
          limitStatus: const CallLimitStatus(remainingSeconds: 720),
        ),
        gateway: FakeCallRoomGateway(agentPresentOnConnect: true),
      );
      await harness.slideToAnswer();
      await harness.emitEventMessage({
        'type': 'CALL_LIMIT_REACHED',
        'v': 1,
        'limitKind': 'PER_CALL',
      });
      await harness.emit(
        const CallRoomMetadataChanged('{"v":1,"end_reason":"limit_reached"}'),
      );
      await harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.roomDeleted),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('12분', findRichText: true), findsOneWidget);
      expect(find.text('다시 통화하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await harness.tearDownScreen();
    });
  });
}
