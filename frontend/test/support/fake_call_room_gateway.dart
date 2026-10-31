import 'dart:async';

import 'package:teeq/features/call/domain/call_room_event.dart';
import 'package:teeq/features/call/domain/call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_termination.dart';

/// 이벤트를 테스트가 주입하고 호출을 기록하는 테스트용 통화 방 게이트웨이.
class FakeCallRoomGateway implements CallRoomGateway {
  FakeCallRoomGateway({
    this.connectError,
    this.reconnectResult = true,
    this.agentPresentOnConnect = false,
  });

  /// 지정하면 [connect]가 이 오류를 던진다.
  /// 연결 중 취소는 `CallRoomConnectionCancelledException()`을 넣어 흉내 낸다.
  final Object? connectError;

  final bool reconnectResult;

  /// true면 [connect] 직후 [CallRoomAgentPresent]를 방출한다.
  final bool agentPresentOnConnect;

  final StreamController<CallRoomEvent> _controller =
      StreamController<CallRoomEvent>.broadcast();

  bool _isLocalHangupEmitted = false;

  int connectCount = 0;
  int reconnectCount = 0;
  int disconnectCount = 0;
  int disposeCount = 0;
  final List<bool> microphoneMutedCalls = <bool>[];
  final List<bool> speakerPreferredCalls = <bool>[];

  /// 테스트가 방 이벤트를 흘려보낸다.
  void emit(CallRoomEvent event) => _controller.add(event);

  @override
  Stream<CallRoomEvent> get events => _controller.stream;

  @override
  Future<void> connect({
    required String serverUrl,
    required String accessToken,
  }) async {
    connectCount += 1;
    _isLocalHangupEmitted = false;
    final failure = connectError;
    if (failure != null) {
      throw failure;
    }
    if (agentPresentOnConnect) {
      emit(const CallRoomAgentPresent());
    }
  }

  @override
  Future<bool> reconnectWithLatestToken() async {
    reconnectCount += 1;
    return reconnectResult;
  }

  @override
  Future<void> setMicrophoneMuted(bool isMuted) async {
    microphoneMutedCalls.add(isMuted);
  }

  @override
  Future<void> setSpeakerOutputPreferred(bool isPreferred) async {
    speakerPreferredCalls.add(isPreferred);
  }

  @override
  Future<void> disconnect() async {
    disconnectCount += 1;
    // 실제 구현처럼 연결 한 번에 직접 끊음 이벤트는 한 번만 방출한다.
    if (_isLocalHangupEmitted) {
      return;
    }
    _isLocalHangupEmitted = true;
    emit(const CallRoomDisconnected(CallDisconnectCause.localHangup));
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    await _controller.close();
  }
}
