import 'dart:async';

import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_room_event.dart';
import 'package:teeq/features/call/domain/call_room_gateway.dart';
import 'package:teeq/features/call/domain/call_termination.dart';

part 'livekit_call_room_gateway.g.dart';

/// LiveKit `Room`으로 통화 방에 연결하는 구현. 연결할 때마다 새 `Room`을 만든다.
///
/// 토큰 값은 로그에 남기지 않는다. 연결 오류 문자열에도 접속 주소(토큰 포함)가 들어갈 수 있어
/// 오류는 타입 이름만 기록한다.
final class LiveKitCallRoomGateway implements CallRoomGateway {
  LiveKitCallRoomGateway(this._logger);

  static const String _logName = 'LiveKitCallRoomGateway';

  final AppLogger _logger;
  final StreamController<CallRoomEvent> _eventController =
      StreamController<CallRoomEvent>.broadcast();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  String? _serverUrl;
  bool _isMicrophoneMuted = false;
  bool _isAgentPresentReported = false;
  bool _isLocalHangupRequested = false;
  bool _isDisposed = false;

  @override
  Stream<CallRoomEvent> get events => _eventController.stream;

  @override
  Future<void> connect({
    required String serverUrl,
    required String accessToken,
  }) async {
    // 새 통화 연결을 시작할 때만 직접 끊음 플래그를 초기화한다(재접속에서는 초기화하지 않는다).
    _isLocalHangupRequested = false;
    _serverUrl = serverUrl;
    _isMicrophoneMuted = false;
    await _connectNewRoom(serverUrl: serverUrl, accessToken: accessToken);
  }

  @override
  Future<bool> reconnectWithLatestToken() async {
    final previousRoom = _room;
    final serverUrl = _serverUrl;
    if (previousRoom == null || serverUrl == null) {
      return false;
    }
    // SDK가 통화 중 갱신한 최신 토큰은 `Room.engine.token`에만 있다(`engine`은 SDK 내부용 @internal).
    // 처음 받은 토큰은 약 11분 뒤 쓸 수 없으므로, 이전 Room을 정리하기 전에 이 값을 꺼내 둔다.
    // ignore: invalid_use_of_internal_member
    final latestToken = previousRoom.engine.token;
    if (latestToken == null || latestToken.isEmpty) {
      return false;
    }
    try {
      await _connectNewRoom(serverUrl: serverUrl, accessToken: latestToken);
      return true;
    } on CallRoomConnectionCancelledException {
      return false;
    } on Object catch (error) {
      _logger.log(
        '최신 토큰으로 방 재접속 실패: ${error.runtimeType}',
        name: _logName,
        level: AppLogLevel.warning,
      );
      return false;
    }
  }

  @override
  Future<void> setMicrophoneMuted(bool isMuted) async {
    _isMicrophoneMuted = isMuted;
    await _room?.localParticipant?.setMicrophoneEnabled(!isMuted);
  }

  @override
  Future<void> setSpeakerOutputPreferred(bool isPreferred) =>
      AudioManager.instance.setSpeakerOutputPreferred(isPreferred);

  /// 직접 끊은 경우는 SDK 이벤트 도착 여부와 상관없이 여기서 한 번만 `localHangup`을 방출한다.
  @override
  Future<void> disconnect() async {
    // 연결 한 번에 직접 끊음은 한 번만 처리한다(새 connect가 플래그를 되돌린다).
    if (_isLocalHangupRequested) {
      return;
    }
    _isLocalHangupRequested = true;
    try {
      await _room?.disconnect();
    } finally {
      _emit(const CallRoomDisconnected(CallDisconnectCause.localHangup));
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _releaseRoom();
    await _eventController.close();
  }

  /// 각 await 뒤에 연결이 취소됐는지(정리·직접 끊음·다른 Room으로 교체) 다시 확인한다.
  /// 취소되면 이 Room을 정리하고 [CallRoomConnectionCancelledException]을 던진다.
  Future<void> _connectNewRoom({
    required String serverUrl,
    required String accessToken,
  }) async {
    await _releaseRoom();
    if (_isConnectionCancelled) {
      throw const CallRoomConnectionCancelledException();
    }
    final room = Room();
    final listener = _subscribe(room);
    _room = room;
    _listener = listener;
    _isAgentPresentReported = false;
    try {
      await room.connect(serverUrl, accessToken);
      _throwIfStale(room);
      await room.localParticipant?.setMicrophoneEnabled(!_isMicrophoneMuted);
      _throwIfStale(room);
    } on Object {
      await _releaseConnectingRoom(room, listener);
      rethrow;
    }
    if (room.remoteParticipants.values.any(_isAgent)) {
      _reportAgentPresent();
    }
  }

  bool get _isConnectionCancelled => _isDisposed || _isLocalHangupRequested;

  void _throwIfStale(Room room) {
    if (_isConnectionCancelled || _room != room) {
      throw const CallRoomConnectionCancelledException();
    }
  }

  /// 실패·취소된 연결의 Room을 정리한다. 아직 추적 중이면 추적을 끊고, 이미 다른 쪽이
  /// 정리했더라도 연결이 뒤늦게 끝났을 수 있어 한 번 더 끊고 해제한다(SDK 해제는 중복 호출에 안전).
  Future<void> _releaseConnectingRoom(
    Room room,
    EventsListener<RoomEvent> listener,
  ) async {
    if (_room == room) {
      _room = null;
      _listener = null;
    }
    await _releaseDetachedRoom(room, listener);
  }

  EventsListener<RoomEvent> _subscribe(Room room) => room.createListener()
    ..on<RoomDisconnectedEvent>(_handleDisconnected)
    ..on<RoomReconnectingEvent>((_) => _emit(const CallRoomReconnecting()))
    ..on<RoomResumingEvent>((_) => _emit(const CallRoomReconnecting()))
    ..on<RoomReconnectedEvent>((_) => _emit(const CallRoomReconnected()))
    ..on<RoomMetadataChangedEvent>(
      (event) => _emit(CallRoomMetadataChanged(event.metadata)),
    )
    ..on<ParticipantConnectedEvent>((event) {
      if (_isAgent(event.participant)) {
        _reportAgentPresent();
      }
    })
    ..on<DataReceivedEvent>(
      (event) =>
          _emit(CallRoomDataReceived(topic: event.topic, payload: event.data)),
    );

  void _handleDisconnected(RoomDisconnectedEvent event) {
    // 직접 끊은 경우는 disconnect()가 이미 방출했다.
    if (_isLocalHangupRequested) {
      return;
    }
    final cause = event.reason == DisconnectReason.roomDeleted
        ? CallDisconnectCause.roomDeleted
        : CallDisconnectCause.connectionLost;
    _emit(CallRoomDisconnected(cause));
  }

  bool _isAgent(RemoteParticipant participant) =>
      participant.kind == ParticipantKind.AGENT;

  /// 연결 한 번에 워커 입장은 한 번만 알린다.
  void _reportAgentPresent() {
    if (_isAgentPresentReported) {
      return;
    }
    _isAgentPresentReported = true;
    _emit(const CallRoomAgentPresent());
  }

  void _emit(CallRoomEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// 리스너를 먼저 해제해 정리 중 이벤트가 새지 않게 한 뒤 Room을 끊고 해제한다.
  Future<void> _releaseRoom() async {
    final listener = _listener;
    final room = _room;
    _listener = null;
    _room = null;
    if (room != null && listener != null) {
      await _releaseDetachedRoom(room, listener);
    }
  }

  Future<void> _releaseDetachedRoom(
    Room room,
    EventsListener<RoomEvent> listener,
  ) async {
    if (!listener.isDisposed) {
      await listener.dispose();
    }
    await room.disconnect();
    if (!room.isDisposed) {
      await room.dispose();
    }
  }
}

@riverpod
CallRoomGateway callRoomGateway(Ref ref) {
  final gateway = LiveKitCallRoomGateway(ref.read(appLoggerProvider));
  ref.onDispose(gateway.dispose);
  return gateway;
}
