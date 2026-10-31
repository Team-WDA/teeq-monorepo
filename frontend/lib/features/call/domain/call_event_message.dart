import 'dart:convert';

import 'package:teeq/features/call/domain/call_limit_kind.dart';

/// AI 서버가 통화 중 보내는 이벤트 데이터 메시지의 토픽.
const String callEventTopic = 'teeq.event';

/// 통화 이벤트 데이터 메시지.
sealed class CallEventMessage {
  const CallEventMessage();
}

/// 통화 종료가 가까워졌다.
final class CallEndingSoonMessage extends CallEventMessage {
  const CallEndingSoonMessage({required this.remainingSeconds});

  final int remainingSeconds;
}

/// 통화 한도에 도달했다.
final class CallLimitReachedMessage extends CallEventMessage {
  const CallLimitReachedMessage({required this.limitKind});

  final CallLimitKind limitKind;
}

/// UTF-8 JSON 바이트를 [CallEventMessage]로 바꾼다. 해석할 수 없으면 null.
CallEventMessage? parseCallEventMessage(List<int> payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(payload));
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  return switch (decoded['type']) {
    'CALL_ENDING_SOON' => switch (decoded['remainingSeconds']) {
      final int remainingSeconds => CallEndingSoonMessage(
        remainingSeconds: remainingSeconds,
      ),
      _ => null,
    },
    'CALL_LIMIT_REACHED' => switch (CallLimitKind.fromServerName(
      decoded['limitKind'] is String ? decoded['limitKind'] as String : null,
    )) {
      final CallLimitKind limitKind => CallLimitReachedMessage(
        limitKind: limitKind,
      ),
      null => null,
    },
    _ => null,
  };
}
