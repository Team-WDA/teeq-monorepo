import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_event_message.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';

List<int> _bytes(String text) => utf8.encode(text);

void main() {
  test('토픽 상수는 teeq.event다', () {
    expect(callEventTopic, 'teeq.event');
  });

  group('parseCallEventMessage', () {
    test('CALL_ENDING_SOON을 파싱한다', () {
      final message = parseCallEventMessage(
        _bytes('{"type":"CALL_ENDING_SOON","v":1,"remainingSeconds":120}'),
      );

      expect(message, isA<CallEndingSoonMessage>());
      expect((message! as CallEndingSoonMessage).remainingSeconds, 120);
    });

    test('CALL_LIMIT_REACHED를 파싱한다', () {
      final message = parseCallEventMessage(
        _bytes(
          '{"type":"CALL_LIMIT_REACHED","v":1,"limitKind":"WHOLE_SERVICE"}',
        ),
      );

      expect(message, isA<CallLimitReachedMessage>());
      expect(
        (message! as CallLimitReachedMessage).limitKind,
        CallLimitKind.wholeService,
      );
    });

    test('추가 필드가 있어도 정상 파싱한다', () {
      final message = parseCallEventMessage(
        _bytes(
          '{"type":"CALL_ENDING_SOON","v":1,"remainingSeconds":30,"extra":"x"}',
        ),
      );

      expect((message! as CallEndingSoonMessage).remainingSeconds, 30);
    });

    test('알 수 없는 type은 null이다', () {
      expect(parseCallEventMessage(_bytes('{"type":"OTHER","v":1}')), isNull);
    });

    test('깨진 JSON은 null이다', () {
      expect(parseCallEventMessage(_bytes('{not json')), isNull);
    });

    test('빈 바이트는 null이다', () {
      expect(parseCallEventMessage(<int>[]), isNull);
    });

    test('알 수 없는 limitKind는 null이다', () {
      expect(
        parseCallEventMessage(
          _bytes('{"type":"CALL_LIMIT_REACHED","v":1,"limitKind":"X"}'),
        ),
        isNull,
      );
    });

    test('remainingSeconds가 숫자가 아니면 null이다', () {
      expect(
        parseCallEventMessage(
          _bytes('{"type":"CALL_ENDING_SOON","v":1,"remainingSeconds":"120"}'),
        ),
        isNull,
      );
    });
  });
}
