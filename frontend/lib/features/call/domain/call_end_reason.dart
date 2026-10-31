import 'dart:convert';

/// LiveKit 방 metadata에 담기는 통화 종료 사유.
enum CallEndReason {
  userHangup,
  userDisconnected,
  limitReached,
  agentError;

  /// 방 metadata(`{"v":1,"end_reason":"agent_error"}`)에서 종료 사유를 읽는다. 해석할 수 없으면 null.
  static CallEndReason? fromRoomMetadata(String? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(metadata);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return switch (decoded['end_reason']) {
      'user_hangup' => CallEndReason.userHangup,
      'user_disconnected' => CallEndReason.userDisconnected,
      'limit_reached' => CallEndReason.limitReached,
      'agent_error' => CallEndReason.agentError,
      _ => null,
    };
  }
}
