import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/body_preview.dart';

void main() {
  group('BodyPreview.fromText', () {
    test('keeps text of exactly the maximum length untruncated', () {
      final text = 'a' * maxBodyPreviewLength;

      final preview = BodyPreview.fromText(text);

      expect(preview.isTruncated, isFalse);
      expect(preview.text, text);
      expect(preview.originalLength, maxBodyPreviewLength);
    });

    test('truncates text one character over the maximum length', () {
      final text = 'a' * (maxBodyPreviewLength + 1);

      final preview = BodyPreview.fromText(text);

      expect(preview.isTruncated, isTrue);
      expect(preview.text.length, maxBodyPreviewLength);
      expect(preview.originalLength, maxBodyPreviewLength + 1);
    });

    test('accepts an empty string', () {
      final preview = BodyPreview.fromText('');

      expect(preview.text, isEmpty);
      expect(preview.isTruncated, isFalse);
      expect(preview.originalLength, 0);
    });

    test('uses 100 KB as the maximum length', () {
      expect(maxBodyPreviewLength, 100 * 1024);
    });
  });
}
