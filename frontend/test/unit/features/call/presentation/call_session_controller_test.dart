import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/permission_handler_gateway.dart';
import 'package:teeq/features/call/data/call_repository_impl.dart';
import 'package:teeq/features/call/data/foreground_call_keep_alive.dart';
import 'package:teeq/features/call/data/livekit_call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_destination.dart';
import 'package:teeq/features/call/domain/call_event_message.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/domain/call_room_event.dart';
import 'package:teeq/features/call/domain/call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';
import 'package:teeq/features/call/domain/call_termination.dart';
import 'package:teeq/features/call/presentation/call_session_controller.dart';
import 'package:teeq/features/call/presentation/call_timing_provider.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/fake_app_permission_gateway.dart';
import '../../../../support/fake_call_keep_alive.dart';
import '../../../../support/fake_call_repository.dart';
import '../../../../support/fake_call_room_gateway.dart';
import '../../../../support/fake_current_member_controller.dart';
import '../../../../support/fake_home_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

/// 첫 요청은 거절, 그 뒤 요청은 허용으로 답하는 권한 게이트웨이.
class _GrantsOnSecondRequestPermissionGateway extends FakeAppPermissionGateway {
  _GrantsOnSecondRequestPermissionGateway();

  AppPermissionStatus _status = AppPermissionStatus.denied;

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async => _status;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    requestCount += 1;
    _status = requestCount >= 2
        ? AppPermissionStatus.granted
        : AppPermissionStatus.denied;
    return _status;
  }
}

/// 재접속 결과와 음소거 실패 시점을 테스트가 정하는 게이트웨이.
class _ControllableCallRoomGateway extends FakeCallRoomGateway {
  _ControllableCallRoomGateway();

  /// 지정하면 [reconnectWithLatestToken]이 이 값이 완료될 때까지 기다렸다가 그 결과를 돌려준다.
  Completer<bool>? reconnectGate;

  /// 지정하면 다음 음소거(true) 요청이 이 게이트가 완료된 뒤 실패한다.
  Completer<void>? failingMuteGate;

  @override
  Future<bool> reconnectWithLatestToken() {
    final gate = reconnectGate;
    if (gate == null) {
      return super.reconnectWithLatestToken();
    }
    reconnectCount += 1;
    return gate.future;
  }

  @override
  Future<void> setMicrophoneMuted(bool isMuted) async {
    final gate = failingMuteGate;
    if (gate == null || !isMuted) {
      return super.setMicrophoneMuted(isMuted);
    }
    failingMuteGate = null;
    microphoneMutedCalls.add(isMuted);
    await gate.future;
    throw StateError('mute failed');
  }
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _callSessionId = 'call-1';

const _startInfo = CallStartInfo(
  callSessionId: _callSessionId,
  maxDurationSeconds: 600,
  serverUrl: 'wss://livekit.example.com',
  accessToken: 'token',
);

final _startTime = DateTime.utc(2026, 11, 1, 12);

class _Harness {
  _Harness({
    required this.async,
    required this.container,
    required this.repository,
    required this.gateway,
    required this.permissionGateway,
    required this.keepAlive,
    required this.errorHandler,
  });

  final FakeAsync async;
  final ProviderContainer container;
  final FakeCallRepository repository;
  final FakeCallRoomGateway gateway;
  final FakeAppPermissionGateway permissionGateway;
  final FakeCallKeepAlive keepAlive;
  final _RecordingErrorHandler errorHandler;

  bool isContainerDisposed = false;

  /// 화면이 닫혀 컨트롤러가 정리되는 상황을 흉내 낸다.
  void disposeContainer() {
    container.dispose();
    isContainerDisposed = true;
    flush();
  }

  CallSessionController get controller =>
      container.read(callSessionControllerProvider.notifier);

  CallPhase get phase => container.read(callSessionControllerProvider);

  void flush() => async.flushMicrotasks();

  void emit(CallRoomEvent event) {
    gateway.emit(event);
    flush();
  }

  void elapse(Duration duration) {
    async.elapse(duration);
    flush();
  }

  /// 권한 허용 상태에서 받고 연결중까지 진행한다.
  void answer() {
    controller.answer();
    flush();
  }

  /// 연결 뒤 워커가 들어와 통화중이 되게 한다.
  void answerAndJoinAgent() {
    answer();
    emit(const CallRoomAgentPresent());
  }
}

/// fakeAsync 안에서 가짜 의존성을 갖춘 컨테이너를 만들고 테스트 본문을 실행한다.
void _runWithHarness(
  void Function(_Harness harness) body, {
  FakeCallRepository? repository,
  FakeCallRoomGateway? gateway,
  FakeAppPermissionGateway? permissionGateway,
}) {
  fakeAsync((async) {
    final callRepository =
        repository ?? FakeCallRepository(startInfo: _startInfo);
    final roomGateway = gateway ?? FakeCallRoomGateway();
    final permission =
        permissionGateway ??
        FakeAppPermissionGateway(initialStatus: AppPermissionStatus.granted);
    final keepAlive = FakeCallKeepAlive();
    final errorHandler = _RecordingErrorHandler();
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        callRepositoryProvider.overrideWithValue(callRepository),
        callRoomGatewayProvider.overrideWithValue(roomGateway),
        appPermissionGatewayProvider.overrideWithValue(permission),
        callKeepAliveProvider.overrideWithValue(keepAlive),
        callClockProvider.overrideWithValue(
          () => _startTime.add(async.elapsed),
        ),
        errorHandlerProvider.overrideWithValue(errorHandler),
        appLoggerProvider.overrideWithValue(AppLogger()),
        currentMemberControllerProvider.overrideWith(
          () => FakeCurrentMemberController(_member),
        ),
        homeRepositoryProvider.overrideWithValue(
          FakeHomeRepository(
            summary: const HomeSummary(
              characterName: '티티',
              characterType: CharacterType.character1,
              characterMood: CharacterMood.welcome,
              personalityTags: ['다정함', '차분함', '유쾌함'],
              greeting: '안녕',
            ),
          ),
        ),
      ],
    );
    // 통화 화면이 홈 요약(캐릭터 이름)을 구독하고 있는 상황을 흉내 낸다.
    container.listen(homeSummaryProvider(_member.memberId), (_, _) {});
    // autoDispose 컨트롤러가 테스트 중 정리되지 않게 구독을 유지한다.
    container.listen(callSessionControllerProvider, (_, _) {});
    async.flushMicrotasks();
    final harness = _Harness(
      async: async,
      container: container,
      repository: callRepository,
      gateway: roomGateway,
      permissionGateway: permission,
      keepAlive: keepAlive,
      errorHandler: errorHandler,
    );
    body(harness);
    if (!harness.isContainerDisposed) {
      harness.disposeContainer();
    }
  });
}

ApiException _apiError(ErrorCode errorCode) =>
    ApiException(errorCode: errorCode, httpStatus: 403);

CallRoomDataReceived _eventData(Map<String, Object?> json) =>
    CallRoomDataReceived(
      topic: callEventTopic,
      payload: utf8.encode(jsonEncode(json)),
    );

Matcher _notice(CallConnectionNoticeKind kind, {required bool callStarted}) =>
    isA<CallConnectionNotice>()
        .having((phase) => phase.kind, 'kind', kind)
        .having((phase) => phase.callStarted, 'callStarted', callStarted);

Matcher _limitReached(CallLimitKind kind, {required bool callStarted}) =>
    isA<CallLimitReached>()
        .having((phase) => phase.limitKind, 'limitKind', kind)
        .having((phase) => phase.callStarted, 'callStarted', callStarted);

final Matcher _finishedHome = isA<CallFinished>().having(
  (phase) => phase.destination,
  'destination',
  isA<CallDestinationHome>(),
);

final Matcher _finishedFeedback = isA<CallFinished>().having(
  (phase) => phase.destination,
  'destination',
  isA<CallDestinationFeedback>().having(
    (destination) => destination.callSessionId,
    'callSessionId',
    _callSessionId,
  ),
);

Matcher _inProgress({Duration? elapsed}) {
  final matcher = isA<CallInProgress>();
  if (elapsed == null) {
    return matcher;
  }
  return matcher.having((phase) => phase.elapsed, 'elapsed', elapsed);
}

CallInProgress _inProgressOf(_Harness harness) =>
    harness.phase as CallInProgress;

void main() {
  test('starts ringing', () {
    _runWithHarness((harness) {
      expect(harness.phase, isA<CallRinging>());
    });
  });

  test('answer starts the call once when slide completes twice', () {
    _runWithHarness((harness) {
      harness.controller.answer();
      harness.controller.answer();
      harness.flush();

      expect(harness.repository.startCallCount, 1);
      expect(harness.gateway.connectCount, 1);
      expect(harness.phase, isA<CallConnecting>());
    });
  });

  group('answer shows permission card when permission denied', () {
    test('거절이면 설정 이동 없이 권한 카드를 보이고 서버를 부르지 않는다', () {
      _runWithHarness(
        (harness) {
          harness.answer();

          expect(
            harness.phase,
            isA<CallPermissionRequired>().having(
              (phase) => phase.shouldOpenSettings,
              'shouldOpenSettings',
              false,
            ),
          );
          expect(harness.repository.startCallCount, 0);
          expect(harness.gateway.connectCount, 0);
        },
        permissionGateway: FakeAppPermissionGateway(
          requestResult: AppPermissionStatus.denied,
        ),
      );
    });

    test('영구 거절이면 설정 이동 권한 카드를 보인다', () {
      _runWithHarness(
        (harness) {
          harness.answer();

          expect(
            harness.phase,
            isA<CallPermissionRequired>().having(
              (phase) => phase.shouldOpenSettings,
              'shouldOpenSettings',
              true,
            ),
          );
          expect(harness.repository.startCallCount, 0);
        },
        permissionGateway: FakeAppPermissionGateway(
          requestResult: AppPermissionStatus.permanentlyDenied,
        ),
      );
    });

    test('다시 시도에서 허용되면 통화 시작으로 이어진다', () {
      _runWithHarness((harness) {
        harness.answer();
        expect(harness.phase, isA<CallPermissionRequired>());

        harness.controller.retryAfterPermissionRequired();
        harness.flush();

        expect(harness.permissionGateway.requestCount, 2);
        expect(harness.repository.startCallCount, 1);
        expect(harness.phase, isA<CallConnecting>());
      }, permissionGateway: _GrantsOnSecondRequestPermissionGateway());
    });

    test('영구 거절 카드의 다시 시도는 설정을 연다', () {
      _runWithHarness(
        (harness) {
          harness.answer();

          harness.controller.retryAfterPermissionRequired();
          harness.flush();

          expect(harness.permissionGateway.openSettingsCount, 1);
          expect(harness.permissionGateway.requestCount, 1);
          expect(harness.phase, isA<CallPermissionRequired>());
        },
        permissionGateway: FakeAppPermissionGateway(
          requestResult: AppPermissionStatus.permanentlyDenied,
        ),
      );
    });

    test('권한 카드의 나중에 하기는 홈으로 끝난다', () {
      _runWithHarness(
        (harness) {
          harness.answer();

          harness.controller.rejectIncomingCall();
          harness.flush();

          expect(harness.phase, _finishedHome);
          expect(harness.repository.startCallCount, 0);
        },
        permissionGateway: FakeAppPermissionGateway(
          requestResult: AppPermissionStatus.denied,
        ),
      );
    });
  });

  test('rejecting the ringing call goes home without server calls', () {
    _runWithHarness((harness) {
      harness.controller.rejectIncomingCall();
      harness.flush();

      expect(harness.phase, _finishedHome);
      expect(harness.repository.startCallCount, 0);
    });
  });

  group('call start errors map to screens', () {
    void expectStartError(ErrorCode errorCode, Matcher expected) {
      _runWithHarness((harness) {
        harness.answer();

        expect(harness.phase, expected);
        expect(harness.errorHandler.handledErrors, isEmpty);
        expect(harness.gateway.connectCount, 0);
      }, repository: FakeCallRepository(startError: _apiError(errorCode)));
    }

    test('하루 한도 부족은 하루 한도 화면이다', () {
      expectStartError(
        ErrorCode.callLimitInsufficient,
        _limitReached(CallLimitKind.perDay, callStarted: false),
      );
    });

    test('서비스 한도 초과는 서비스 전체 한도 화면이다', () {
      expectStartError(
        ErrorCode.callServiceLimitExceeded,
        _limitReached(CallLimitKind.wholeService, callStarted: false),
      );
    });

    test('AI 서버 장애와 진행 중 통화는 연결 실패 카드다', () {
      expectStartError(
        ErrorCode.aiServerUnavailable,
        _notice(CallConnectionNoticeKind.connectionFailed, callStarted: false),
      );
      expectStartError(
        ErrorCode.callAlreadyInProgress,
        _notice(CallConnectionNoticeKind.connectionFailed, callStarted: false),
      );
    });

    test('그 외 에러는 중앙 처리기에 넘기고 울리는 화면으로 돌아간다', () {
      final error = _apiError(ErrorCode.unknown);
      _runWithHarness((harness) {
        harness.answer();

        expect(harness.phase, isA<CallRinging>());
        expect(harness.errorHandler.handledErrors, [error]);
        expect(harness.gateway.connectCount, 0);
      }, repository: FakeCallRepository(startError: error));
    });

    test('하루 한도 화면에서 통화가 시작되지 않았으면 피드백 버튼도 홈으로 간다', () {
      _runWithHarness(
        (harness) {
          harness.answer();

          harness.controller.finishLimitScreenToFeedback();
          harness.flush();

          expect(harness.phase, _finishedHome);
        },
        repository: FakeCallRepository(
          startError: _apiError(ErrorCode.callLimitInsufficient),
        ),
      );
    });

    test('연결 실패 카드의 다시 연결하기는 통화 시작을 다시 요청한다', () {
      _runWithHarness(
        (harness) {
          harness.answer();
          expect(
            harness.phase,
            _notice(
              CallConnectionNoticeKind.connectionFailed,
              callStarted: false,
            ),
          );

          harness.controller.retryConnection();
          harness.flush();

          expect(harness.repository.startCallCount, 2);
        },
        repository: FakeCallRepository(
          startError: _apiError(ErrorCode.aiServerUnavailable),
        ),
      );
    });
  });

  test('connection failure while joining the room shows connection failed '
      'notice', () {
    _runWithHarness(
      (harness) {
        harness.answer();

        expect(
          harness.phase,
          _notice(
            CallConnectionNoticeKind.connectionFailed,
            callStarted: false,
          ),
        );
        expect(harness.errorHandler.handledErrors, isEmpty);
      },
      gateway: FakeCallRoomGateway(connectError: StateError('connect failed')),
    );
  });

  test('connect cancelled is not treated as failure', () {
    _runWithHarness(
      (harness) {
        harness.answer();

        expect(harness.phase, isNot(isA<CallConnectionNotice>()));
        expect(harness.errorHandler.handledErrors, isEmpty);
      },
      gateway: FakeCallRoomGateway(
        connectError: const CallRoomConnectionCancelledException(),
      ),
    );
  });

  test('connect enables microphone and prefers earpiece', () {
    _runWithHarness((harness) {
      harness.answer();

      expect(harness.gateway.microphoneMutedCalls, [false]);
      expect(harness.gateway.speakerPreferredCalls, [false]);
    });
  });

  test('agent already present at connect goes straight to in progress', () {
    _runWithHarness((harness) {
      harness.answer();

      expect(harness.phase, _inProgress(elapsed: Duration.zero));
      final inProgress = _inProgressOf(harness);
      expect(inProgress.isMuted, isFalse);
      expect(inProgress.isSpeakerOn, isFalse);
      expect(harness.keepAlive.startedBodies, ['티티와 통화 중이에요']);

      harness.elapse(const Duration(seconds: 1));
      expect(harness.phase, _inProgress(elapsed: const Duration(seconds: 1)));

      harness.elapse(const Duration(seconds: 1));
      expect(harness.phase, _inProgress(elapsed: const Duration(seconds: 2)));
    }, gateway: FakeCallRoomGateway(agentPresentOnConnect: true));
  });

  test('agent wait timeout', () {
    _runWithHarness((harness) {
      harness.answer();

      harness.elapse(const Duration(seconds: 19));
      expect(harness.phase, isA<CallConnecting>());

      harness.elapse(const Duration(seconds: 1));
      expect(
        harness.phase,
        _notice(CallConnectionNoticeKind.connectionTimeout, callStarted: false),
      );
    });
  });

  test('reconnect notice only after grace', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();

      harness.emit(const CallRoomReconnecting());
      harness.elapse(const Duration(seconds: 4));
      harness.emit(const CallRoomReconnected());
      harness.elapse(const Duration(seconds: 2));
      expect(_inProgressOf(harness).isReconnectNoticeVisible, isFalse);

      harness.emit(const CallRoomReconnecting());
      harness.elapse(const Duration(seconds: 5));
      expect(_inProgressOf(harness).isReconnectNoticeVisible, isTrue);

      harness.emit(const CallRoomReconnected());
      expect(_inProgressOf(harness).isReconnectNoticeVisible, isFalse);
    });
  });

  test('end before agent joins goes home without feedback', () {
    _runWithHarness((harness) {
      harness.answer();
      expect(harness.phase, isA<CallConnecting>());

      harness.controller.confirmEnd();
      harness.flush();

      expect(harness.gateway.disconnectCount, 1);
      expect(harness.phase, _finishedHome);
    });
  });

  test('end after agent joined goes to feedback with callSessionId', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();

      harness.controller.requestEnd();
      expect(_inProgressOf(harness).isEndConfirmationVisible, isTrue);

      harness.controller.cancelEnd();
      expect(_inProgressOf(harness).isEndConfirmationVisible, isFalse);

      harness.controller.requestEnd();
      harness.controller.confirmEnd();
      harness.flush();

      expect(harness.gateway.disconnectCount, 1);
      expect(harness.phase, _finishedFeedback);
    });
  });

  group('room deleted with agent_error shows connection failed notice', () {
    void emitAgentErrorRoomDeleted(_Harness harness) {
      harness.emit(
        const CallRoomMetadataChanged('{"v":1,"end_reason":"agent_error"}'),
      );
      harness.emit(const CallRoomDisconnected(CallDisconnectCause.roomDeleted));
    }

    test('통화가 시작된 뒤면 카드를 닫을 때 피드백으로 간다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        emitAgentErrorRoomDeleted(harness);

        expect(
          harness.phase,
          _notice(CallConnectionNoticeKind.connectionFailed, callStarted: true),
        );

        harness.controller.closeConnectionNotice();
        harness.flush();
        expect(harness.phase, _finishedFeedback);
      });
    });

    test('통화가 시작되기 전이면 카드를 닫을 때 홈으로 간다', () {
      _runWithHarness((harness) {
        harness.answer();
        emitAgentErrorRoomDeleted(harness);

        expect(
          harness.phase,
          _notice(
            CallConnectionNoticeKind.connectionFailed,
            callStarted: false,
          ),
        );

        harness.controller.closeConnectionNotice();
        harness.flush();
        expect(harness.phase, _finishedHome);
      });
    });
  });

  group('limit message then room deleted shows limit screen', () {
    void emitLimitReachedRoomDeleted(
      _Harness harness, {
      required bool withMessage,
    }) {
      if (withMessage) {
        harness.emit(
          _eventData({
            'type': 'CALL_LIMIT_REACHED',
            'v': 1,
            'limitKind': 'PER_DAY',
          }),
        );
        // 한도 메시지를 받은 순간에는 화면을 바꾸지 않는다.
        expect(harness.phase, isA<CallInProgress>());
      }
      harness.emit(
        const CallRoomMetadataChanged('{"v":1,"end_reason":"limit_reached"}'),
      );
      harness.emit(const CallRoomDisconnected(CallDisconnectCause.roomDeleted));
    }

    test('주 버튼은 피드백으로 간다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        emitLimitReachedRoomDeleted(harness, withMessage: true);

        expect(
          harness.phase,
          _limitReached(CallLimitKind.perDay, callStarted: true),
        );

        harness.controller.finishLimitScreenToFeedback();
        harness.flush();
        expect(harness.phase, _finishedFeedback);
      });
    });

    test('보조 버튼은 홈으로 간다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        emitLimitReachedRoomDeleted(harness, withMessage: true);

        harness.controller.finishLimitScreenToHome();
        harness.flush();
        expect(harness.phase, _finishedHome);
      });
    });

    test('메시지 없이 limit_reached만 오면 일반 종료로 피드백에 간다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        emitLimitReachedRoomDeleted(harness, withMessage: false);

        expect(harness.phase, _finishedFeedback);
      });
    });
  });

  test('connection lost shows connection notice', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();

      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );

      expect(
        harness.phase,
        _notice(CallConnectionNoticeKind.connectionLost, callStarted: true),
      );
    });
  });

  group('retryConnection', () {
    void loseConnectionAfterTenSeconds(_Harness harness) {
      harness.answerAndJoinAgent();
      harness.elapse(const Duration(seconds: 10));
      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );
      harness.elapse(const Duration(seconds: 5));
    }

    test('재접속 뒤 워커가 보이면 처음 시작 시점 기준으로 통화를 이어간다', () {
      _runWithHarness((harness) {
        loseConnectionAfterTenSeconds(harness);

        harness.controller.retryConnection();
        harness.flush();
        expect(harness.gateway.reconnectCount, 1);

        harness.emit(const CallRoomAgentPresent());
        expect(
          harness.phase,
          _inProgress(elapsed: const Duration(seconds: 15)),
        );

        harness.elapse(const Duration(seconds: 1));
        expect(
          harness.phase,
          _inProgress(elapsed: const Duration(seconds: 16)),
        );
      });
    });

    test('재접속 뒤 워커가 안 보이면 20초 뒤 연결 시간 초과다', () {
      _runWithHarness((harness) {
        loseConnectionAfterTenSeconds(harness);

        harness.controller.retryConnection();
        harness.flush();
        harness.elapse(const Duration(seconds: 19));
        expect(harness.phase, isA<CallConnecting>());

        harness.elapse(const Duration(seconds: 1));
        expect(
          harness.phase,
          _notice(
            CallConnectionNoticeKind.connectionTimeout,
            callStarted: true,
          ),
        );
      });
    });

    test('재접속에 실패하면 연결 실패 카드다', () {
      _runWithHarness((harness) {
        loseConnectionAfterTenSeconds(harness);

        harness.controller.retryConnection();
        harness.flush();

        expect(
          harness.phase,
          _notice(CallConnectionNoticeKind.connectionFailed, callStarted: true),
        );
      }, gateway: FakeCallRoomGateway(reconnectResult: false));
    });
  });

  group('ending soon message shows card once', () {
    test('같은 메시지가 두 번 와도 카드는 한 번만 뜬다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        final endingSoon = _eventData({
          'type': 'CALL_ENDING_SOON',
          'v': 1,
          'remainingSeconds': 60,
        });

        harness.emit(endingSoon);
        expect(_inProgressOf(harness).isEndingSoonVisible, isTrue);

        harness.emit(endingSoon);
        expect(_inProgressOf(harness).isEndingSoonVisible, isTrue);

        harness.controller.dismissEndingSoon();
        expect(_inProgressOf(harness).isEndingSoonVisible, isFalse);

        harness.emit(endingSoon);
        expect(_inProgressOf(harness).isEndingSoonVisible, isFalse);
      });
    });

    test('음수 남은 시간도 카드만 띄운다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();

        harness.emit(
          _eventData({
            'type': 'CALL_ENDING_SOON',
            'v': 1,
            'remainingSeconds': -5,
          }),
        );

        expect(_inProgressOf(harness).isEndingSoonVisible, isTrue);
      });
    });

    test('알 수 없는 type, 깨진 payload, 다른 토픽은 상태를 바꾸지 않는다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        final before = harness.phase;

        harness.emit(_eventData({'type': 'UNKNOWN', 'v': 1}));
        harness.emit(
          CallRoomDataReceived(
            topic: callEventTopic,
            payload: utf8.encode('{not json'),
          ),
        );
        harness.emit(
          const CallRoomDataReceived(topic: callEventTopic, payload: []),
        );
        harness.emit(
          CallRoomDataReceived(
            topic: 'other.topic',
            payload: utf8.encode(
              jsonEncode({
                'type': 'CALL_ENDING_SOON',
                'v': 1,
                'remainingSeconds': 60,
              }),
            ),
          ),
        );

        expect(harness.phase, same(before));
      });
    });
  });

  test('mute and speaker toggles call the gateway', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();

      harness.controller.toggleMute();
      harness.flush();
      expect(harness.gateway.microphoneMutedCalls, [false, true]);
      expect(_inProgressOf(harness).isMuted, isTrue);

      harness.controller.toggleSpeaker();
      harness.flush();
      expect(harness.gateway.speakerPreferredCalls, [false, true]);
      expect(_inProgressOf(harness).isSpeakerOn, isTrue);

      harness.controller.toggleMute();
      harness.flush();
      expect(harness.gateway.microphoneMutedCalls, [false, true, false]);
      expect(_inProgressOf(harness).isMuted, isFalse);
    });
  });

  test('keep alive stopped on finish', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      expect(harness.keepAlive.startedBodies, hasLength(1));
      expect(harness.keepAlive.stopCount, 0);

      harness.controller.confirmEnd();
      harness.flush();

      expect(harness.phase, _finishedFeedback);
      expect(harness.keepAlive.stopCount, 1);
      expect(harness.gateway.disposeCount, 1);
    });
  });

  test('keep alive stopped when connection is lost', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();

      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );

      expect(harness.keepAlive.stopCount, 1);
    });
  });

  group('connection timeout card keeps the microphone off', () {
    void reachTimeout(_Harness harness) {
      harness.answer();
      harness.elapse(const Duration(seconds: 20));
      expect(
        harness.phase,
        _notice(CallConnectionNoticeKind.connectionTimeout, callStarted: false),
      );
    }

    test('연결 시간 초과 카드에서는 마이크를 끈다', () {
      _runWithHarness((harness) {
        reachTimeout(harness);

        expect(harness.gateway.microphoneMutedCalls, [false, true]);
      });
    });

    test('카드가 떠 있는 동안 워커가 늦게 들어오면 통화중으로 회복한다', () {
      _runWithHarness((harness) {
        reachTimeout(harness);

        harness.emit(const CallRoomAgentPresent());

        expect(harness.phase, _inProgress(elapsed: Duration.zero));
        expect(harness.gateway.microphoneMutedCalls.last, isFalse);
        expect(harness.keepAlive.startedBodies, hasLength(1));

        harness.elapse(const Duration(seconds: 1));
        expect(harness.phase, _inProgress(elapsed: const Duration(seconds: 1)));
      });
    });

    test('카드의 다시 연결하기는 재접속 뒤 마이크를 다시 켠다', () {
      _runWithHarness((harness) {
        reachTimeout(harness);

        harness.controller.retryConnection();
        harness.flush();

        expect(harness.gateway.reconnectCount, 1);
        expect(harness.gateway.microphoneMutedCalls, [false, true, false]);
        expect(harness.phase, isA<CallConnecting>());
      });
    });
  });

  group('ending before the agent joins needs no confirmation', () {
    test('시작 요청 중에 끝내면 늦게 온 시작 결과를 버리고 홈으로 끝난다', () {
      final startGate = Completer<void>();
      _runWithHarness(
        (harness) {
          harness.answer();
          expect(harness.phase, isA<CallStarting>());

          harness.controller.confirmEnd();
          harness.flush();
          expect(harness.phase, _finishedHome);
          expect(harness.gateway.disposeCount, 1);

          startGate.complete();
          harness.flush();
          expect(harness.phase, _finishedHome);
          expect(harness.gateway.connectCount, 0);
        },
        repository: FakeCallRepository(
          startInfo: _startInfo,
          startGate: startGate,
        ),
      );
    });

    test('연결중의 종료 요청은 확인 카드 없이 홈으로 끝난다', () {
      _runWithHarness((harness) {
        harness.answer();
        expect(harness.phase, isA<CallConnecting>());

        harness.controller.requestEnd();
        harness.flush();

        expect(harness.phase, _finishedHome);
        expect(harness.gateway.disposeCount, 1);
      });
    });
  });

  test('ending soon card survives reconnect', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      harness.emit(
        _eventData({
          'type': 'CALL_ENDING_SOON',
          'v': 1,
          'remainingSeconds': 60,
        }),
      );
      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );

      harness.controller.retryConnection();
      harness.flush();
      harness.emit(const CallRoomAgentPresent());

      expect(_inProgressOf(harness).isEndingSoonVisible, isTrue);
    });
  });

  test('late failed reconnect does not overwrite a newer notice', () {
    final gateway = _ControllableCallRoomGateway();
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );
      final reconnectGate = Completer<bool>();
      gateway.reconnectGate = reconnectGate;

      harness.controller.retryConnection();
      harness.flush();
      expect(harness.phase, isA<CallConnecting>());

      harness.emit(
        const CallRoomDisconnected(CallDisconnectCause.connectionLost),
      );
      expect(
        harness.phase,
        _notice(CallConnectionNoticeKind.connectionLost, callStarted: true),
      );

      reconnectGate.complete(false);
      harness.flush();
      expect(
        harness.phase,
        _notice(CallConnectionNoticeKind.connectionLost, callStarted: true),
      );
    }, gateway: gateway);
  });

  test('mute rollback ignores an outdated failure', () {
    final gateway = _ControllableCallRoomGateway();
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      final failingMuteGate = Completer<void>();
      gateway.failingMuteGate = failingMuteGate;

      harness.controller.toggleMute();
      harness.controller.toggleMute();
      harness.controller.toggleMute();
      harness.flush();
      expect(_inProgressOf(harness).isMuted, isTrue);

      failingMuteGate.complete();
      harness.flush();

      // 마지막 요청(음소거)이 성공했으므로 첫 요청의 실패로 되돌리지 않는다.
      expect(_inProgressOf(harness).isMuted, isTrue);
    }, gateway: gateway);
  });

  test('mute failure of the latest request rolls back', () {
    final gateway = _ControllableCallRoomGateway();
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      final failingMuteGate = Completer<void>();
      gateway.failingMuteGate = failingMuteGate;

      harness.controller.toggleMute();
      harness.flush();
      failingMuteGate.complete();
      harness.flush();

      expect(_inProgressOf(harness).isMuted, isFalse);
    }, gateway: gateway);
  });

  group('disposing the controller releases everything', () {
    test('통화중에 정리되면 방·포그라운드 유지·타이머를 정리한다', () {
      _runWithHarness((harness) {
        harness.answerAndJoinAgent();
        harness.emit(const CallRoomReconnecting());
        var changeCount = 0;
        harness.container.listen(
          callSessionControllerProvider,
          (_, _) => changeCount += 1,
        );

        harness.disposeContainer();
        harness.elapse(const Duration(seconds: 30));

        expect(harness.gateway.disposeCount, 1);
        expect(harness.keepAlive.stopCount, 1);
        expect(changeCount, 0);
        expect(harness.async.pendingTimers, isEmpty);
      });
    });

    test('연결중에 정리되면 워커 대기 타이머가 남지 않는다', () {
      _runWithHarness((harness) {
        harness.answer();

        harness.disposeContainer();
        harness.elapse(const Duration(seconds: 30));

        expect(harness.gateway.disposeCount, 1);
        expect(harness.async.pendingTimers, isEmpty);
      });
    });
  });

  test('retryConnection from the in-call reconnect card', () {
    _runWithHarness((harness) {
      harness.answerAndJoinAgent();
      harness.emit(const CallRoomReconnecting());
      harness.elapse(const Duration(seconds: 5));
      expect(_inProgressOf(harness).isReconnectNoticeVisible, isTrue);

      harness.controller.retryConnection();
      harness.flush();
      expect(harness.gateway.reconnectCount, 1);
      expect(harness.phase, isA<CallConnecting>());

      harness.emit(const CallRoomAgentPresent());
      expect(harness.phase, _inProgress(elapsed: const Duration(seconds: 5)));
      expect(_inProgressOf(harness).isReconnectNoticeVisible, isFalse);
    });
  });

  group('restartAfterLimitReached', () {
    void reachLimitMidCall(_Harness harness) {
      harness.answerAndJoinAgent();
      harness.emit(
        _eventData({
          'type': 'CALL_ENDING_SOON',
          'v': 1,
          'remainingSeconds': 30,
        }),
      );
      harness.emit(
        _eventData({
          'type': 'CALL_LIMIT_REACHED',
          'v': 1,
          'limitKind': 'PER_CALL',
        }),
      );
      harness.emit(
        const CallRoomMetadataChanged('{"v":1,"end_reason":"limit_reached"}'),
      );
      harness.emit(const CallRoomDisconnected(CallDisconnectCause.roomDeleted));
      expect(
        harness.phase,
        _limitReached(CallLimitKind.perCall, callStarted: true),
      );
    }

    test('통화 중 한도 화면에서 다시 통화하면 새 통화를 처음부터 시작한다', () {
      _runWithHarness((harness) {
        reachLimitMidCall(harness);
        harness.elapse(const Duration(seconds: 7));

        harness.controller.restartAfterLimitReached();
        harness.flush();
        expect(harness.phase, isA<CallRinging>());
        expect(harness.gateway.disposeCount, 0);
        expect(harness.async.pendingTimers, isEmpty);
        expect(harness.keepAlive.stopCount, 1);

        harness.answer();
        expect(harness.repository.startCallCount, 2);
        expect(harness.gateway.connectCount, 2);
        expect(harness.phase, isA<CallConnecting>());

        harness.emit(const CallRoomAgentPresent());
        expect(harness.phase, _inProgress(elapsed: Duration.zero));
        expect(_inProgressOf(harness).isEndingSoonVisible, isFalse);
        expect(harness.keepAlive.startedBodies, hasLength(2));

        harness.elapse(const Duration(seconds: 1));
        expect(harness.phase, _inProgress(elapsed: const Duration(seconds: 1)));

        // 이전 통화에서 띄운 곧 종료 카드는 새 통화에서 다시 뜰 수 있다.
        harness.emit(
          _eventData({
            'type': 'CALL_ENDING_SOON',
            'v': 1,
            'remainingSeconds': 30,
          }),
        );
        expect(_inProgressOf(harness).isEndingSoonVisible, isTrue);
      });
    });

    test('이전 통화의 한도 종류와 metadata는 새 통화에 남지 않는다', () {
      _runWithHarness((harness) {
        reachLimitMidCall(harness);
        harness.controller.restartAfterLimitReached();
        harness.flush();
        harness.answerAndJoinAgent();

        harness.emit(
          const CallRoomDisconnected(CallDisconnectCause.roomDeleted),
        );

        expect(harness.phase, _finishedFeedback);
      });
    });

    test('시작 거절로 뜬 한도 화면에서도 다시 울리는 화면으로 돌아간다', () {
      _runWithHarness(
        (harness) {
          harness.answer();
          expect(
            harness.phase,
            _limitReached(CallLimitKind.perDay, callStarted: false),
          );

          harness.controller.restartAfterLimitReached();
          harness.flush();
          expect(harness.phase, isA<CallRinging>());

          harness.answer();
          expect(harness.repository.startCallCount, 2);
        },
        repository: FakeCallRepository(
          startError: _apiError(ErrorCode.callLimitInsufficient),
        ),
      );
    });

    test('한도 화면이 아니면 아무것도 하지 않는다', () {
      _runWithHarness((harness) {
        harness.controller.restartAfterLimitReached();
        expect(harness.phase, isA<CallRinging>());

        harness.answer();
        harness.controller.restartAfterLimitReached();
        harness.flush();
        expect(harness.phase, isA<CallConnecting>());

        harness.emit(const CallRoomAgentPresent());
        final inProgress = harness.phase;
        harness.controller.restartAfterLimitReached();
        expect(harness.phase, same(inProgress));

        harness.emit(
          const CallRoomDisconnected(CallDisconnectCause.connectionLost),
        );
        harness.controller.restartAfterLimitReached();
        expect(harness.phase, isA<CallConnectionNotice>());

        harness.controller.closeConnectionNotice();
        harness.flush();
        harness.controller.restartAfterLimitReached();
        expect(harness.phase, _finishedFeedback);
      });
    });
  });
}
