import 'package:teeq/features/call/domain/call_end_reason.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';

/// 방 연결이 끊긴 원인.
enum CallDisconnectCause { localHangup, roomDeleted, connectionLost }

/// 통화가 끝난 결과.
sealed class CallTermination {
  const CallTermination();
}

/// 정상 종료.
final class CallEndedNormally extends CallTermination {
  const CallEndedNormally({required this.callStarted});

  final bool callStarted;
}

/// 에이전트 오류로 종료.
final class CallEndedByAgentError extends CallTermination {
  const CallEndedByAgentError({required this.callStarted});

  final bool callStarted;
}

/// 한도 도달로 종료.
final class CallEndedByLimit extends CallTermination {
  const CallEndedByLimit({required this.limitKind});

  final CallLimitKind limitKind;
}

/// 네트워크 문제로 연결이 끊김.
final class CallConnectionLost extends CallTermination {
  const CallConnectionLost();
}

/// 끊긴 원인, 마지막 방 metadata, 받은 한도 종류로 통화 종료 결과를 판정한다.
CallTermination resolveCallTermination({
  required CallDisconnectCause cause,
  required String? lastRoomMetadata,
  required CallLimitKind? receivedLimitKind,
  required bool callStarted,
}) {
  switch (cause) {
    case CallDisconnectCause.localHangup:
      return CallEndedNormally(callStarted: callStarted);
    case CallDisconnectCause.connectionLost:
      return const CallConnectionLost();
    case CallDisconnectCause.roomDeleted:
      final endReason = CallEndReason.fromRoomMetadata(lastRoomMetadata);
      if (endReason == CallEndReason.agentError) {
        return CallEndedByAgentError(callStarted: callStarted);
      }
      if (endReason == CallEndReason.limitReached &&
          receivedLimitKind != null) {
        return CallEndedByLimit(limitKind: receivedLimitKind);
      }
      return CallEndedNormally(callStarted: callStarted);
  }
}
