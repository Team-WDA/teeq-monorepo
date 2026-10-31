import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/presentation/call_remaining_time_format.dart';

void main() {
  group('formatTodayRemainingMinutes', () {
    test('0초 이하는 0분이다', () {
      expect(formatTodayRemainingMinutes(0), '0분');
      expect(formatTodayRemainingMinutes(-5), '0분');
    });

    test('1~59초는 1분 미만이다', () {
      expect(formatTodayRemainingMinutes(30), '1분 미만');
      expect(formatTodayRemainingMinutes(59), '1분 미만');
    });

    test('60초 이상은 내림한 분이다', () {
      expect(formatTodayRemainingMinutes(60), '1분');
      expect(formatTodayRemainingMinutes(720), '12분');
      expect(formatTodayRemainingMinutes(779), '12분');
    });
  });
}
