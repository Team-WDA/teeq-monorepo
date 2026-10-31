import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';
import 'package:teeq/features/call/domain/call_termination.dart';

const _agentError = '{"v":1,"end_reason":"agent_error"}';
const _limitReached = '{"v":1,"end_reason":"limit_reached"}';
const _userHangup = '{"v":1,"end_reason":"user_hangup"}';

void main() {
  group('resolveCallTermination', () {
    test('localHangup은 정상 종료다', () {
      final termination = resolveCallTermination(
        cause: CallDisconnectCause.localHangup,
        lastRoomMetadata: null,
        receivedLimitKind: null,
        callStarted: true,
      );

      expect(termination, isA<CallEndedNormally>());
      expect((termination as CallEndedNormally).callStarted, isTrue);
    });

    test('roomDeleted와 agent_error는 에이전트 오류 종료다', () {
      final termination = resolveCallTermination(
        cause: CallDisconnectCause.roomDeleted,
        lastRoomMetadata: _agentError,
        receivedLimitKind: null,
        callStarted: false,
      );

      expect(termination, isA<CallEndedByAgentError>());
      expect((termination as CallEndedByAgentError).callStarted, isFalse);
    });

    test('roomDeleted와 limit_reached와 한도 종류가 있으면 한도 종료다', () {
      final termination = resolveCallTermination(
        cause: CallDisconnectCause.roomDeleted,
        lastRoomMetadata: _limitReached,
        receivedLimitKind: CallLimitKind.perDay,
        callStarted: true,
      );

      expect(termination, isA<CallEndedByLimit>());
      expect((termination as CallEndedByLimit).limitKind, CallLimitKind.perDay);
    });

    test('limit_reached여도 한도 종류가 없으면 정상 종료다', () {
      final termination = resolveCallTermination(
        cause: CallDisconnectCause.roomDeleted,
        lastRoomMetadata: _limitReached,
        receivedLimitKind: null,
        callStarted: true,
      );

      expect(termination, isA<CallEndedNormally>());
    });

    test('roomDeleted에 metadata가 없거나 user_hangup이면 정상 종료다', () {
      for (final metadata in <String?>[null, _userHangup]) {
        final termination = resolveCallTermination(
          cause: CallDisconnectCause.roomDeleted,
          lastRoomMetadata: metadata,
          receivedLimitKind: null,
          callStarted: true,
        );

        expect(termination, isA<CallEndedNormally>());
      }
    });

    test('connectionLost는 연결 끊김이다', () {
      final termination = resolveCallTermination(
        cause: CallDisconnectCause.connectionLost,
        lastRoomMetadata: _agentError,
        receivedLimitKind: null,
        callStarted: true,
      );

      expect(termination, isA<CallConnectionLost>());
    });
  });
}
