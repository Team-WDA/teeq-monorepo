import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';

void main() {
  group('FeedbackInputLimits.truncate', () {
    test('truncate_keepsTextAtExactLimit', () {
      final text = '가' * FeedbackInputLimits.reasonMaxLength;

      expect(
        FeedbackInputLimits.truncate(text, FeedbackInputLimits.reasonMaxLength),
        text,
      );
    });

    test('truncate_cutsPlainTextByCodeUnits', () {
      expect(FeedbackInputLimits.truncate('abcdef', 3), 'abc');
    });

    test('truncate_dropsWholeSurrogatePairThatDoesNotFit', () {
      final text = '${'가' * 99}😀';

      final result = FeedbackInputLimits.truncate(text, 100);

      expect(result, '가' * 99);
    });

    test('truncate_keepsSurrogatePairThatFits', () {
      final text = '${'가' * 98}😀';

      expect(FeedbackInputLimits.truncate(text, 100), text);
    });
  });
}
