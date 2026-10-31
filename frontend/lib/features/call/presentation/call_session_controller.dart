import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/permission_handler_gateway.dart';
import 'package:teeq/features/call/data/call_repository_impl.dart';
import 'package:teeq/features/call/data/foreground_call_keep_alive.dart';
import 'package:teeq/features/call/data/livekit_call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_destination.dart';
import 'package:teeq/features/call/domain/call_event_message.dart';
import 'package:teeq/features/call/domain/call_keep_alive.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/domain/call_room_event.dart';
import 'package:teeq/features/call/domain/call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_start_failure.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';
import 'package:teeq/features/call/domain/call_termination.dart';
import 'package:teeq/features/call/presentation/call_session_timers.dart';
import 'package:teeq/features/call/presentation/call_timing_provider.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

part 'call_session_controller.g.dart';

/// 통화 화면 하나의 상태 머신. 울리는 화면에서 시작해 [CallFinished]로 끝나며,
/// 화면 이동은 하지 않고 [CallFinished.destination]만 정한다.
@riverpod
class CallSessionController extends _$CallSessionController {
  static const String _logName = 'CallSessionController';

  late CallRoomGateway _gateway;
  late CallKeepAlive _keepAlive;
  late CallSessionTimers _timers;
  late DateTime Function() _clock;

  /// 통화 시도마다(시작·종료) 늘어난다. 늦게 끝난 비동기 작업이 새 상태를 건드리지 않게 구분한다.
  int _attempt = 0;
  bool _isGatewayDisposed = false;
  bool _isKeepAliveActive = false;

  String? _callSessionId;

  /// 워커가 한 번이라도 보였는지 여부. true면 통화가 시작된 것으로 본다.
  bool _callStarted = false;
  bool _isAgentPresent = false;

  /// 워커가 처음 보인 시각. 재접속 뒤에도 경과 시간은 이 시각부터 센다.
  DateTime? _callStartedAt;
  String? _lastRoomMetadata;
  CallLimitKind? _receivedLimitKind;
  bool _isEndingSoonShown = false;
  bool _isEndingSoonVisible = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  /// 음소거·스피커 전환 요청 순번. 실패한 요청이 가장 최근 요청일 때만 되돌린다.
  int _muteRequestSequence = 0;
  int _speakerRequestSequence = 0;

  @override
  CallPhase build() {
    _gateway = ref.watch(callRoomGatewayProvider);
    _keepAlive = ref.watch(callKeepAliveProvider);
    _timers = CallSessionTimers(ref.watch(callTimingProvider));
    _clock = ref.watch(callClockProvider);
    // 연결 직후 방출되는 이벤트를 놓치지 않도록 연결 전에 구독한다.
    final subscription = _gateway.events.listen(_handleRoomEvent);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _timers.cancelAll();
      _stopKeepAlive();
      _disposeGateway();
    });
    return const CallRinging();
  }

  /// 밀어서 통화하기 완료. 여러 번 불려도 한 번만 진행한다.
  Future<void> answer() async {
    if (state is! CallRinging) {
      return;
    }
    state = const CallRequestingPermission();
    try {
      await _checkPermissionThenStart();
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      ref.read(errorHandlerProvider).handle(error);
      state = const CallRinging();
    }
  }

  /// 울리는 화면 거절과 권한 카드의 "나중에 하기". 통화를 시작하지 않고 홈으로 끝낸다.
  void rejectIncomingCall() {
    if (state is CallRinging || state is CallPermissionRequired) {
      _finish(const CallDestinationHome());
    }
  }

  /// 권한 카드의 "권한 허용하기". 이미 허용됐으면 바로 시작하고, 영구 거절이면 설정을 연다.
  Future<void> retryAfterPermissionRequired() async {
    final current = state;
    if (current is! CallPermissionRequired) {
      return;
    }
    state = const CallRequestingPermission();
    try {
      final permissionGateway = ref.read(appPermissionGatewayProvider);
      final status = await permissionGateway.status(AppPermission.microphone);
      if (!ref.mounted) {
        return;
      }
      if (status == AppPermissionStatus.granted) {
        await _startCall();
      } else if (current.shouldOpenSettings) {
        await permissionGateway.openSettings();
        if (ref.mounted) {
          state = current;
        }
      } else {
        await _requestPermissionThenStart();
      }
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      ref.read(errorHandlerProvider).handle(error);
      state = current;
    }
  }

  /// 종료 요청. 워커가 보이기 전(시작 요청 중·연결중)에는 확인 없이 바로 끝낸다.
  void requestEnd() {
    if (_isWaitingForAgent) {
      _endWhileWaitingForAgent();
      return;
    }
    _updateInProgress(
      (phase) => phase.copyWith(isEndConfirmationVisible: true),
    );
  }

  void cancelEnd() => _updateInProgress(
    (phase) => phase.copyWith(isEndConfirmationVisible: false),
  );

  /// 방을 나가고 통화를 끝낸다. 워커가 보이기 전이면 진행 중인 시작을 버리고 바로 끝낸다.
  Future<void> confirmEnd() async {
    if (_isWaitingForAgent) {
      _endWhileWaitingForAgent();
      return;
    }
    if (state is! CallInProgress) {
      return;
    }
    final attempt = _attempt;
    try {
      await _gateway.disconnect();
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      _logWarning('통화 방 나가기 실패', error);
    }
    // 보통은 직접 끊음 이벤트가 먼저 처리해 이미 끝나 있다.
    if (!_isStale(attempt)) {
      _finish(_destinationAfterCall());
    }
  }

  Future<void> toggleMute() async {
    final current = state;
    if (current is! CallInProgress) {
      return;
    }
    final previousIsMuted = current.isMuted;
    final sequence = ++_muteRequestSequence;
    _setMuted(!previousIsMuted);
    try {
      await _gateway.setMicrophoneMuted(!previousIsMuted);
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      _logWarning('음소거 전환 실패', error);
      // 그 사이 새 전환이 있었으면 그 결과가 실제 상태이므로 되돌리지 않는다.
      if (sequence == _muteRequestSequence) {
        _setMuted(previousIsMuted);
      }
    }
  }

  Future<void> toggleSpeaker() async {
    final current = state;
    if (current is! CallInProgress) {
      return;
    }
    final previousIsSpeakerOn = current.isSpeakerOn;
    final sequence = ++_speakerRequestSequence;
    _setSpeakerOn(!previousIsSpeakerOn);
    try {
      await _gateway.setSpeakerOutputPreferred(!previousIsSpeakerOn);
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      _logWarning('스피커 전환 실패', error);
      if (sequence == _speakerRequestSequence) {
        _setSpeakerOn(previousIsSpeakerOn);
      }
    }
  }

  void dismissEndingSoon() {
    _isEndingSoonVisible = false;
    _updateInProgress((phase) => phase.copyWith(isEndingSoonVisible: false));
  }

  /// 안내 카드의 "다시 연결하기". 연결 실패는 새 통화를 시작하고, 시간 초과·끊김·재연결 중은
  /// SDK가 갱신한 최신 토큰으로 같은 방에 다시 들어간다.
  Future<void> retryConnection() async {
    final current = state;
    if (current is CallConnectionNotice) {
      if (current.kind == CallConnectionNoticeKind.connectionFailed) {
        // 이미 시작된 통화였다면 새 세션이 생기고, 이전 세션의 피드백은 홈 안전망이 연다.
        await _startCall();
      } else {
        await _reconnect();
      }
    } else if (current is CallInProgress && current.isReconnectNoticeVisible) {
      await _reconnect();
    }
  }

  /// 안내 카드의 닫기·통화 마치기. 통화가 시작됐으면 피드백, 아니면 홈으로 끝낸다.
  void closeConnectionNotice() {
    if (state is CallConnectionNotice) {
      _finish(_destinationAfterCall());
    }
  }

  void finishLimitScreenToFeedback() {
    if (state is CallLimitReached) {
      _finish(_destinationAfterCall());
    }
  }

  void finishLimitScreenToHome() {
    if (state is CallLimitReached) {
      _finish(const CallDestinationHome());
    }
  }

  /// 한도 화면의 "다시 통화하기". 이전 통화 값을 모두 비우고 울리는 화면으로 돌아간다.
  /// 게이트웨이와 이벤트 구독은 그대로 다시 쓴다(새 연결은 [answer]가 만든다).
  void restartAfterLimitReached() {
    if (state is! CallLimitReached) {
      return;
    }
    // 한도 화면은 항상 `_stopAttempt`로 들어와 포그라운드 유지가 이미 멈춰 있다.
    _beginAttempt();
    state = const CallRinging();
  }

  Future<void> _checkPermissionThenStart() async {
    final status = await ref
        .read(appPermissionGatewayProvider)
        .status(AppPermission.microphone);
    if (!ref.mounted) {
      return;
    }
    switch (status) {
      case AppPermissionStatus.granted:
        await _startCall();
      case AppPermissionStatus.permanentlyDenied:
        state = const CallPermissionRequired(shouldOpenSettings: true);
      case AppPermissionStatus.denied:
        await _requestPermissionThenStart();
    }
  }

  Future<void> _requestPermissionThenStart() async {
    final result = await ref
        .read(appPermissionGatewayProvider)
        .request(AppPermission.microphone);
    if (!ref.mounted) {
      return;
    }
    if (result == AppPermissionStatus.granted) {
      await _startCall();
      return;
    }
    state = CallPermissionRequired(
      shouldOpenSettings: result == AppPermissionStatus.permanentlyDenied,
    );
  }

  /// 통화 시작 API → 방 연결 → 마이크 켜기·수화기 출력 → 워커 대기.
  Future<void> _startCall() async {
    final attempt = _beginAttempt();
    state = const CallStarting();
    final CallStartInfo startInfo;
    try {
      startInfo = await ref.read(callRepositoryProvider).startCall();
    } on Object catch (error) {
      if (!_isStale(attempt)) {
        _showStartFailure(error);
      }
      return;
    }
    if (_isStale(attempt)) {
      return;
    }
    _callSessionId = startInfo.callSessionId;
    try {
      await _gateway.connect(
        serverUrl: startInfo.serverUrl,
        accessToken: startInfo.accessToken,
      );
      await _gateway.setMicrophoneMuted(false);
      await _gateway.setSpeakerOutputPreferred(false);
    } on CallRoomConnectionCancelledException {
      // 화면이 닫히거나 사용자가 끊어 연결을 멈춘 것이라 실패가 아니다.
      return;
    } on Object catch (error) {
      if (!_isStale(attempt)) {
        _logWarning('통화 방 연결 실패', error);
        _showNotice(CallConnectionNoticeKind.connectionFailed);
      }
      return;
    }
    if (!_isStale(attempt)) {
      _waitForAgent();
    }
  }

  /// 새 통화 시도를 시작하며 이전 통화의 값을 비운다.
  int _beginAttempt() {
    _attempt += 1;
    _timers.cancelAll();
    _callSessionId = null;
    _callStarted = false;
    _isAgentPresent = false;
    _callStartedAt = null;
    _lastRoomMetadata = null;
    _receivedLimitKind = null;
    _isEndingSoonShown = false;
    _isEndingSoonVisible = false;
    _isMuted = false;
    _isSpeakerOn = false;
    return _attempt;
  }

  bool _isStale(int attempt) => !ref.mounted || attempt != _attempt;

  void _showStartFailure(Object error) {
    switch (mapCallStartError(error)) {
      case CallStartDailyLimitExceeded():
        _stopAttempt(
          const CallLimitReached(
            limitKind: CallLimitKind.perDay,
            callStarted: false,
          ),
        );
      case CallStartServiceLimitExceeded():
        _stopAttempt(
          const CallLimitReached(
            limitKind: CallLimitKind.wholeService,
            callStarted: false,
          ),
        );
      case CallStartConnectionFailed():
        _showNotice(CallConnectionNoticeKind.connectionFailed);
      case null:
        ref.read(errorHandlerProvider).handle(error);
        state = const CallRinging();
    }
  }

  Future<void> _reconnect() async {
    final attempt = _attempt;
    _leaveCall();
    _isAgentPresent = false;
    state = const CallConnecting();
    final isReconnected = await _gateway.reconnectWithLatestToken();
    if (_isStale(attempt)) {
      return;
    }
    if (!isReconnected) {
      _showNotice(CallConnectionNoticeKind.connectionFailed);
      return;
    }
    // 시간 초과 카드에서 꺼 둔 마이크를 사용자가 고른 상태로 되돌린다.
    unawaited(_applyMicrophoneMuted(_isMuted));
    if (state is CallConnecting) {
      _waitForAgent();
    }
  }

  /// 연결중으로 바꾸고, 워커가 이미 보였으면 바로 통화중으로, 아니면 대기 시간을 잰다.
  void _waitForAgent() {
    state = const CallConnecting();
    if (_isAgentPresent) {
      _enterInProgress();
      return;
    }
    _timers.startAgentWait(() {
      if (state is CallConnecting) {
        _showNotice(CallConnectionNoticeKind.connectionTimeout);
        // 카드가 떠 있는 동안 사용자 목소리가 방에 나가지 않게 마이크를 끈다.
        unawaited(_applyMicrophoneMuted(true));
      }
    });
  }

  void _enterInProgress() {
    _timers.cancelAgentWait();
    _callStarted = true;
    final startedAt = _callStartedAt ??= _clock();
    state = CallInProgress(
      elapsed: _clock().difference(startedAt),
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      isEndConfirmationVisible: false,
      // 재접속 뒤 돌아와도 닫지 않은 곧 종료 카드는 그대로 보여 준다.
      isEndingSoonVisible: _isEndingSoonVisible,
      isReconnectNoticeVisible: false,
    );
    // 타이머는 화면 갱신용이고 값은 시각 차이로 계산해 타이머가 멈췄다 돌아와도 맞다.
    _timers.startElapsedRefresh(() {
      _updateInProgress(
        (phase) => phase.copyWith(elapsed: _clock().difference(startedAt)),
      );
    });
    _startKeepAlive();
  }

  void _handleRoomEvent(CallRoomEvent event) {
    switch (event) {
      case CallRoomAgentPresent():
        _handleAgentPresent();
      case CallRoomReconnecting():
        _handleReconnecting();
      case CallRoomReconnected():
        _timers.cancelReconnectNoticeGrace();
        _updateInProgress(
          (phase) => phase.copyWith(isReconnectNoticeVisible: false),
        );
      case CallRoomMetadataChanged(:final metadata):
        _lastRoomMetadata = metadata;
      case CallRoomDataReceived(:final topic, :final payload):
        _handleDataMessage(topic, payload);
      case CallRoomDisconnected(:final cause):
        _handleDisconnected(cause);
    }
  }

  void _handleAgentPresent() {
    _isAgentPresent = true;
    final current = state;
    if (current is CallConnecting) {
      _enterInProgress();
    } else if (current is CallConnectionNotice &&
        current.kind == CallConnectionNoticeKind.connectionTimeout) {
      // 시간 초과 카드가 뜬 뒤 워커가 늦게 들어오면 통화를 회복한다.
      _attempt += 1;
      unawaited(_applyMicrophoneMuted(_isMuted));
      _enterInProgress();
    }
  }

  /// 자동 재연결이 유예 시간을 넘길 때만 재연결 카드를 띄운다.
  void _handleReconnecting() {
    if (state is! CallInProgress) {
      return;
    }
    _timers.startReconnectNoticeGrace(() {
      _updateInProgress(
        (phase) => phase.copyWith(isReconnectNoticeVisible: true),
      );
    });
  }

  void _handleDataMessage(String? topic, List<int> payload) {
    if (topic != callEventTopic) {
      return;
    }
    switch (parseCallEventMessage(payload)) {
      case CallEndingSoonMessage():
        // 남은 시간 숫자는 화면에 보이지 않으므로 쓰지 않는다(음수여도 카드만 띄운다).
        if (state is CallInProgress && !_isEndingSoonShown) {
          _isEndingSoonShown = true;
          _isEndingSoonVisible = true;
          _updateInProgress(
            (phase) => phase.copyWith(isEndingSoonVisible: true),
          );
        }
      case CallLimitReachedMessage(:final limitKind):
        // 한도 화면은 방이 닫힌 뒤에 보여 준다.
        _receivedLimitKind = limitKind;
      case null:
        return;
    }
  }

  void _handleDisconnected(CallDisconnectCause cause) {
    if (state is! CallConnecting && state is! CallInProgress) {
      return;
    }
    final termination = resolveCallTermination(
      cause: cause,
      lastRoomMetadata: _lastRoomMetadata,
      receivedLimitKind: _receivedLimitKind,
      callStarted: _callStarted,
    );
    switch (termination) {
      case CallEndedNormally():
        _finish(_destinationAfterCall());
      case CallEndedByAgentError():
        _showNotice(CallConnectionNoticeKind.connectionFailed);
      case CallEndedByLimit(:final limitKind):
        _stopAttempt(
          CallLimitReached(limitKind: limitKind, callStarted: _callStarted),
        );
      case CallConnectionLost():
        _showNotice(CallConnectionNoticeKind.connectionLost);
    }
  }

  void _showNotice(CallConnectionNoticeKind kind) {
    _stopAttempt(CallConnectionNotice(kind: kind, callStarted: _callStarted));
  }

  /// 진행 중인 시도를 멈추고 [phase]로 바꾼다. 세대를 올려 늦게 끝난 비동기 작업이 이 상태를 덮지 않게 한다.
  void _stopAttempt(CallPhase phase) {
    _attempt += 1;
    _leaveCall();
    state = phase;
  }

  bool get _isWaitingForAgent =>
      state is CallStarting || state is CallConnecting;

  /// 워커가 보이기 전에 끝낸다. 시작·연결 결과는 버리고 방을 나간다(재접속 중이었다면 피드백으로 간다).
  void _endWhileWaitingForAgent() {
    if (state is CallConnecting) {
      unawaited(_disconnectLoggingFailure());
    }
    _finish(_destinationAfterCall());
  }

  Future<void> _disconnectLoggingFailure() async {
    try {
      await _gateway.disconnect();
    } on Object catch (error) {
      if (ref.mounted) {
        _logWarning('통화 방 나가기 실패', error);
      }
    }
  }

  Future<void> _applyMicrophoneMuted(bool isMuted) async {
    try {
      await _gateway.setMicrophoneMuted(isMuted);
    } on Object catch (error) {
      if (ref.mounted) {
        _logWarning('마이크 상태 변경 실패', error);
      }
    }
  }

  CallDestination _destinationAfterCall() {
    final callSessionId = _callSessionId;
    if (_callStarted && callSessionId != null) {
      return CallDestinationFeedback(callSessionId: callSessionId);
    }
    return const CallDestinationHome();
  }

  /// 통화를 끝낸다. 방과 포그라운드 유지를 정리하고, 진행 중인 비동기 작업은 무시되게 한다.
  void _finish(CallDestination destination) {
    _stopAttempt(CallFinished(destination: destination));
    _disposeGateway();
  }

  /// 통화중을 벗어날 때 타이머와 포그라운드 유지를 멈춘다.
  void _leaveCall() {
    _timers.cancelAll();
    _stopKeepAlive();
  }

  void _startKeepAlive() {
    if (_isKeepAliveActive) {
      return;
    }
    _isKeepAliveActive = true;
    unawaited(
      _keepAlive.start(
        notificationBody: buildCallNotificationBody(_characterName()),
      ),
    );
  }

  void _stopKeepAlive() {
    if (!_isKeepAliveActive) {
      return;
    }
    _isKeepAliveActive = false;
    unawaited(_keepAlive.stop());
  }

  void _disposeGateway() {
    if (_isGatewayDisposed) {
      return;
    }
    _isGatewayDisposed = true;
    unawaited(_gateway.dispose());
  }

  /// 통화 화면이 구독 중인 홈 요약의 캐릭터 이름. 아직 없으면 null.
  String? _characterName() {
    final member = ref.read(currentMemberControllerProvider);
    if (member == null) {
      return null;
    }
    return ref.read(homeSummaryProvider(member.memberId)).value?.characterName;
  }

  void _setMuted(bool isMuted) {
    _isMuted = isMuted;
    _updateInProgress((phase) => phase.copyWith(isMuted: isMuted));
  }

  void _setSpeakerOn(bool isSpeakerOn) {
    _isSpeakerOn = isSpeakerOn;
    _updateInProgress((phase) => phase.copyWith(isSpeakerOn: isSpeakerOn));
  }

  void _updateInProgress(CallInProgress Function(CallInProgress) update) {
    final current = state;
    if (current is CallInProgress) {
      state = update(current);
    }
  }

  void _logWarning(String message, Object error) {
    ref
        .read(appLoggerProvider)
        .log(
          '$message: ${error.runtimeType}',
          name: _logName,
          level: AppLogLevel.warning,
        );
  }
}
