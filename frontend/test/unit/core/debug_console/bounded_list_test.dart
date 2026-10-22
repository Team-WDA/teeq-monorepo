import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/bounded_list.dart';
import 'package:teeq/core/logging/app_log_level.dart';

void main() {
  group('appendBounded', () {
    test('appends to the end while under capacity', () {
      final result = appendBounded([1, 2], 3, capacity: 5);

      expect(result, [1, 2, 3]);
    });

    test('drops the oldest item when capacity is exceeded', () {
      final result = appendBounded([1, 2, 3], 4, capacity: 3);

      expect(result, [2, 3, 4]);
    });

    test('does not modify the original list', () {
      final original = [1, 2, 3];

      appendBounded(original, 4, capacity: 3);

      expect(original, [1, 2, 3]);
    });

    test('returns an unmodifiable list', () {
      final result = appendBounded([1], 2, capacity: 3);

      expect(() => result.add(3), throwsUnsupportedError);
    });

    test('uses 500 as the default capacity', () {
      final full = List<int>.generate(debugConsoleEntryCapacity, (i) => i);

      final result = appendBounded(full, -1);

      expect(debugConsoleEntryCapacity, 500);
      expect(result, hasLength(500));
      expect(result.first, 1);
      expect(result.last, -1);
    });
  });

  group('AppLogLevel', () {
    test('maps to dart:developer level values', () {
      expect(AppLogLevel.debug.developerLogValue, 500);
      expect(AppLogLevel.info.developerLogValue, 800);
      expect(AppLogLevel.warning.developerLogValue, 900);
      expect(AppLogLevel.error.developerLogValue, 1000);
    });
  });
}
