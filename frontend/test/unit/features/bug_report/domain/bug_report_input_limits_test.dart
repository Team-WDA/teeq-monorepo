import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/bug_report/domain/bug_report_input_limits.dart';

void main() {
  group('mergeImagePaths', () {
    test('appends picked paths and never exceeds the limit', () {
      final merged = BugReportInputLimits.mergeImagePaths(
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
      );

      expect(merged, ['a', 'b', 'c', 'd', 'e']);
    });

    test('skips paths that are already attached', () {
      final merged = BugReportInputLimits.mergeImagePaths(
        ['a', 'b'],
        ['b', 'c'],
      );

      expect(merged, ['a', 'b', 'c']);
    });
  });
}
