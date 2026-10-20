import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/my_page/domain/profile_image_rule.dart';

void main() {
  ProfileImageIssue? issueOf(String fileName, int byteLength) =>
      ProfileImageRule.issueOf(fileName: fileName, byteLength: byteLength);

  group('확장자', () {
    test('jpg·jpeg·png는 대소문자와 무관하게 허용한다', () {
      for (final fileName in [
        'a.jpg',
        'a.JPG',
        'a.jpeg',
        'a.JpEg',
        'a.png',
        'a.PNG',
      ]) {
        expect(issueOf(fileName, 1000), isNull, reason: fileName);
      }
    });

    test('webp·heic·확장자 없음은 unsupportedFormat', () {
      expect(issueOf('a.webp', 1000), ProfileImageIssue.unsupportedFormat);
      expect(issueOf('a.heic', 1000), ProfileImageIssue.unsupportedFormat);
      expect(issueOf('photo', 1000), ProfileImageIssue.unsupportedFormat);
      expect(issueOf('photo.', 1000), ProfileImageIssue.unsupportedFormat);
    });

    test('점이 여러 개여도 마지막 확장자를 본다', () {
      expect(issueOf('my.photo.png', 1000), isNull);
      expect(issueOf('my.png.gif', 1000), ProfileImageIssue.unsupportedFormat);
    });
  });

  group('크기', () {
    const maxByteLength = 5 * 1024 * 1024;

    test('상한 정확히는 허용한다', () {
      expect(ProfileImageRule.maxByteLength, 5242880);
      expect(issueOf('a.png', maxByteLength), isNull);
    });

    test('상한을 1바이트 넘으면 tooLarge', () {
      expect(issueOf('a.png', maxByteLength + 1), ProfileImageIssue.tooLarge);
    });

    test('0바이트는 unsupportedFormat', () {
      expect(issueOf('a.png', 0), ProfileImageIssue.unsupportedFormat);
    });

    test('형식 위반이 크기 위반보다 우선한다', () {
      expect(
        issueOf('a.webp', maxByteLength + 1),
        ProfileImageIssue.unsupportedFormat,
      );
    });
  });
}
