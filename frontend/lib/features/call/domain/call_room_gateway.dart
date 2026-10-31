import 'package:teeq/features/call/domain/call_room_event.dart';

/// 통화 방(LiveKit) 연결 계약. 테스트에서는 가짜 구현으로 바꾼다.
///
/// 계약:
/// - [connect]가 끝난 뒤 워커가 이미 방에 있으면 [CallRoomAgentPresent]를 한 번 방출한다.
/// - [disconnect]는 연결 한 번에 `CallRoomDisconnected(CallDisconnectCause.localHangup)`을
///   한 번만 방출한다(두 번 불러도 한 번).
/// - 연결 중에 [dispose]되거나 [disconnect]되면 [connect]는 [CallRoomConnectionCancelledException]을
///   던지고, [reconnectWithLatestToken]은 false를 돌려준다.
abstract interface class CallRoomGateway {
  Stream<CallRoomEvent> get events;

  Future<void> connect({
    required String serverUrl,
    required String accessToken,
  });

  /// 최신 토큰으로 다시 연결한다. 성공하면 true.
  Future<bool> reconnectWithLatestToken();

  Future<void> setMicrophoneMuted(bool isMuted);

  Future<void> setSpeakerOutputPreferred(bool isPreferred);

  Future<void> disconnect();

  Future<void> dispose();
}

/// 연결 도중 게이트웨이가 정리되거나 사용자가 직접 끊어 연결을 중단했다.
final class CallRoomConnectionCancelledException implements Exception {
  const CallRoomConnectionCancelledException();

  @override
  String toString() => 'CallRoomConnectionCancelledException';
}
