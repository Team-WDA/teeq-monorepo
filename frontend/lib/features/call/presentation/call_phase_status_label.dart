import 'package:teeq/features/call/domain/call_elapsed_format.dart';
import 'package:teeq/features/call/domain/call_phase.dart';

/// 통화 화면 상단 캐릭터 이름 위에 놓는 단계별 상태 문구(시안 문구 그대로).
String callPhaseStatusLabel(CallPhase phase) => switch (phase) {
  CallRinging() || CallRequestingPermission() => 'TeeQ',
  CallPermissionRequired() => '연결 실패',
  CallStarting() || CallConnecting() => '연결중',
  CallInProgress(:final isReconnectNoticeVisible, :final elapsed) =>
    isReconnectNoticeVisible ? '재연결 중' : formatCallElapsed(elapsed),
  CallConnectionNotice(:final kind) => switch (kind) {
    CallConnectionNoticeKind.connectionFailed => '연결 실패',
    CallConnectionNoticeKind.connectionTimeout => '연결시간 초과',
    CallConnectionNoticeKind.connectionLost => '재연결 중',
  },
  CallLimitReached() || CallFinished() => '통화 종료',
};
