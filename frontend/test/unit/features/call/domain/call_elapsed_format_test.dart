import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_elapsed_format.dart';

void main() {
  group('formatCallElapsed', () {
    test('mm:ss 형식으로 만든다', () {
      expect(formatCallElapsed(Duration.zero), '00:00');
      expect(formatCallElapsed(const Duration(seconds: 12)), '00:12');
      expect(
        formatCallElapsed(const Duration(minutes: 9, seconds: 5)),
        '09:05',
      );
    });

    test('60분 이상은 분이 그대로 늘어난다', () {
      expect(formatCallElapsed(const Duration(minutes: 75)), '75:00');
    });
  });
}
