import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_keep_alive.dart';

void main() {
  group('buildCallNotificationBody', () {
    test('받침이 없는 이름에는 "와"를 붙인다', () {
      expect(buildCallNotificationBody('티티'), '티티와 통화 중이에요');
    });

    test('받침이 있는 이름에는 "과"를 붙인다', () {
      expect(buildCallNotificationBody('달'), '달과 통화 중이에요');
    });

    test('이름이 빈 문자열이면 이름 없는 문구를 쓴다', () {
      expect(buildCallNotificationBody(''), '통화 중이에요');
    });

    test('이름이 없으면 이름 없는 문구를 쓴다', () {
      expect(buildCallNotificationBody(null), '통화 중이에요');
    });
  });
}
