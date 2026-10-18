import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/network/media_url.dart';

void main() {
  test(
    'mediaUrl_baseEndsWithSlashAndPathStartsWithSlash_joinsWithOneSlash',
    () {
      expect(
        mediaUrl('https://a.kr/', '/media/x.jpg'),
        'https://a.kr/media/x.jpg',
      );
    },
  );

  test('mediaUrl_neitherHasSlash_joinsWithOneSlash', () {
    expect(mediaUrl('https://a.kr', 'media/x.jpg'), 'https://a.kr/media/x.jpg');
  });

  test('mediaUrl_exactlyOneSlashBetween_keepsIt', () {
    expect(
      mediaUrl('https://a.kr', '/media/x.jpg'),
      'https://a.kr/media/x.jpg',
    );
  });

  test('mediaUrl_emptyBaseUrl_throwsArgumentError', () {
    expect(() => mediaUrl('', '/media/x.jpg'), throwsArgumentError);
  });
}
