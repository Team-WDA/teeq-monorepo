import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_end_reason.dart';

String _metadata(String reason) => '{"v":1,"end_reason":"$reason"}';

void main() {
  group('CallEndReason.fromRoomMetadata', () {
    test('각 종료 사유를 읽는다', () {
      expect(
        CallEndReason.fromRoomMetadata(_metadata('agent_error')),
        CallEndReason.agentError,
      );
      expect(
        CallEndReason.fromRoomMetadata(_metadata('limit_reached')),
        CallEndReason.limitReached,
      );
      expect(
        CallEndReason.fromRoomMetadata(_metadata('user_hangup')),
        CallEndReason.userHangup,
      );
      expect(
        CallEndReason.fromRoomMetadata(_metadata('user_disconnected')),
        CallEndReason.userDisconnected,
      );
    });

    test('null, 빈 문자열, 깨진 JSON, 알 수 없는 값은 null이다', () {
      expect(CallEndReason.fromRoomMetadata(null), isNull);
      expect(CallEndReason.fromRoomMetadata(''), isNull);
      expect(CallEndReason.fromRoomMetadata('{broken'), isNull);
      expect(CallEndReason.fromRoomMetadata(_metadata('unknown')), isNull);
    });
  });
}
