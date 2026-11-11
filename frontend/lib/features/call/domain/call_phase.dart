import 'package:teeq/features/call/domain/call_destination.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';

/// 연결 안내 화면의 종류.
enum CallConnectionNoticeKind {
  connectionFailed,
  connectionTimeout,
  connectionLost,
}

/// 통화 화면의 단계.
sealed class CallPhase {
  const CallPhase();
}

/// 발신 중 화면.
final class CallRinging extends CallPhase {
  const CallRinging();
}

/// 마이크 권한을 요청하는 중.
final class CallRequestingPermission extends CallPhase {
  const CallRequestingPermission();
}

/// 마이크 권한이 필요하다.
final class CallPermissionRequired extends CallPhase {
  const CallPermissionRequired({required this.shouldOpenSettings});

  /// true이면 시스템 설정을 열어 권한을 켜도록 안내한다.
  final bool shouldOpenSettings;
}

/// 음소거·스피커 버튼을 쓸 수 있는 단계. 통화 시작 요청 중부터 통화 중까지 이어진다.
sealed class CallControlsPhase extends CallPhase {
  const CallControlsPhase();

  bool get isMuted;
  bool get isSpeakerOn;

  CallControlsPhase copyWithControls({
    required bool isMuted,
    required bool isSpeakerOn,
  });
}

/// 통화 시작 API를 호출하는 중.
final class CallStarting extends CallControlsPhase {
  const CallStarting({this.isMuted = false, this.isSpeakerOn = false});

  @override
  final bool isMuted;
  @override
  final bool isSpeakerOn;

  @override
  CallStarting copyWithControls({
    required bool isMuted,
    required bool isSpeakerOn,
  }) => CallStarting(isMuted: isMuted, isSpeakerOn: isSpeakerOn);
}

/// LiveKit 방에 연결하고 상대를 기다리는 중.
final class CallConnecting extends CallControlsPhase {
  const CallConnecting({this.isMuted = false, this.isSpeakerOn = false});

  @override
  final bool isMuted;
  @override
  final bool isSpeakerOn;

  @override
  CallConnecting copyWithControls({
    required bool isMuted,
    required bool isSpeakerOn,
  }) => CallConnecting(isMuted: isMuted, isSpeakerOn: isSpeakerOn);
}

/// 통화 중.
final class CallInProgress extends CallControlsPhase {
  const CallInProgress({
    required this.elapsed,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isEndConfirmationVisible,
    required this.isEndingSoonVisible,
    required this.isReconnectNoticeVisible,
  });

  final Duration elapsed;
  @override
  final bool isMuted;
  @override
  final bool isSpeakerOn;
  final bool isEndConfirmationVisible;
  final bool isEndingSoonVisible;
  final bool isReconnectNoticeVisible;

  CallInProgress copyWith({
    Duration? elapsed,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isEndConfirmationVisible,
    bool? isEndingSoonVisible,
    bool? isReconnectNoticeVisible,
  }) {
    return CallInProgress(
      elapsed: elapsed ?? this.elapsed,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isEndConfirmationVisible:
          isEndConfirmationVisible ?? this.isEndConfirmationVisible,
      isEndingSoonVisible: isEndingSoonVisible ?? this.isEndingSoonVisible,
      isReconnectNoticeVisible:
          isReconnectNoticeVisible ?? this.isReconnectNoticeVisible,
    );
  }

  @override
  CallInProgress copyWithControls({
    required bool isMuted,
    required bool isSpeakerOn,
  }) => copyWith(isMuted: isMuted, isSpeakerOn: isSpeakerOn);
}

/// 연결 실패·시간 초과·끊김 안내.
final class CallConnectionNotice extends CallPhase {
  const CallConnectionNotice({required this.kind, required this.callStarted});

  final CallConnectionNoticeKind kind;

  /// 통화가 실제로 시작된 뒤에 발생했는지 여부.
  final bool callStarted;
}

/// 한도 도달 안내.
final class CallLimitReached extends CallPhase {
  const CallLimitReached({required this.limitKind, required this.callStarted});

  final CallLimitKind limitKind;
  final bool callStarted;
}

/// 통화가 끝나 [destination]으로 이동한다.
final class CallFinished extends CallPhase {
  const CallFinished({required this.destination});

  final CallDestination destination;
}
