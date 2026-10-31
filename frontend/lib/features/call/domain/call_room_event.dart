import 'package:teeq/features/call/domain/call_termination.dart';

/// 통화 방에서 올라오는 이벤트.
sealed class CallRoomEvent {
  const CallRoomEvent();
}

/// AI 워커(에이전트)가 방에 들어와 있다.
final class CallRoomAgentPresent extends CallRoomEvent {
  const CallRoomAgentPresent();
}

/// 연결이 끊겨 다시 붙는 중이다.
final class CallRoomReconnecting extends CallRoomEvent {
  const CallRoomReconnecting();
}

/// 다시 연결되었다.
final class CallRoomReconnected extends CallRoomEvent {
  const CallRoomReconnected();
}

/// 방 metadata가 바뀌었다.
final class CallRoomMetadataChanged extends CallRoomEvent {
  const CallRoomMetadataChanged(this.metadata);

  final String? metadata;
}

/// 데이터 메시지를 받았다.
final class CallRoomDataReceived extends CallRoomEvent {
  const CallRoomDataReceived({this.topic, required this.payload});

  final String? topic;
  final List<int> payload;
}

/// 방 연결이 끊겼다.
final class CallRoomDisconnected extends CallRoomEvent {
  const CallRoomDisconnected(this.cause);

  final CallDisconnectCause cause;
}
