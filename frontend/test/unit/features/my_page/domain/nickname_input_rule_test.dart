import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/my_page/domain/nickname_input_rule.dart';

void main() {
  group('NicknameInputRule.issueOf', () {
    test('빈 문자열은 이슈가 없다', () {
      expect(NicknameInputRule.issueOf(''), isNull);
    });

    test('1자는 tooShort', () {
      expect(NicknameInputRule.issueOf('가'), NicknameInputIssue.tooShort);
    });

    test('2자와 10자는 유효하다', () {
      expect(NicknameInputRule.issueOf('소연'), isNull);
      expect(NicknameInputRule.issueOf('가나다라마바사아자차'), isNull);
    });

    test('11자는 tooLong', () {
      expect(
        NicknameInputRule.issueOf('가나다라마바사아자차카'),
        NicknameInputIssue.tooLong,
      );
    });

    test('특수문자가 있으면 invalidCharacter', () {
      expect(
        NicknameInputRule.issueOf('소연!'),
        NicknameInputIssue.invalidCharacter,
      );
    });

    test('영문·숫자가 있으면 invalidCharacter', () {
      expect(
        NicknameInputRule.issueOf('소연A'),
        NicknameInputIssue.invalidCharacter,
      );
      expect(
        NicknameInputRule.issueOf('소연12'),
        NicknameInputIssue.invalidCharacter,
      );
    });

    test('공백은 허용되지 않는 문자다', () {
      expect(
        NicknameInputRule.issueOf('소연 이'),
        NicknameInputIssue.invalidCharacter,
      );
      expect(
        NicknameInputRule.issueOf(' 소연'),
        NicknameInputIssue.invalidCharacter,
      );
    });

    test('허용 문자 위반이 길이 위반보다 우선한다', () {
      expect(
        NicknameInputRule.issueOf('!'),
        NicknameInputIssue.invalidCharacter,
      );
      expect(
        NicknameInputRule.issueOf('가나다라마바사아자차카!'),
        NicknameInputIssue.invalidCharacter,
      );
    });

    test('한글 2~10자는 유효하다', () {
      expect(NicknameInputRule.issueOf('소연이'), isNull);
    });
  });

  group('NicknameInputRule.isSubmittable', () {
    test('빈 입력은 제출할 수 없다', () {
      expect(NicknameInputRule.isSubmittable('', '소연'), isFalse);
    });

    test('이슈가 있으면 제출할 수 없다', () {
      expect(NicknameInputRule.isSubmittable('가', '소연'), isFalse);
      expect(NicknameInputRule.isSubmittable('소연!', '소연'), isFalse);
    });

    test('현재 닉네임과 같으면 제출할 수 없다', () {
      expect(NicknameInputRule.isSubmittable('소연', '소연'), isFalse);
    });

    test('영문이 섞이면 제출할 수 없다', () {
      expect(NicknameInputRule.isSubmittable('소연a', '소연'), isFalse);
    });

    test('유효하고 다른 닉네임은 제출할 수 있다', () {
      expect(NicknameInputRule.isSubmittable('새닉네임', '소연'), isTrue);
    });
  });

  test('카운터용 최대 길이는 10이다', () {
    expect(NicknameInputRule.maxLength, 10);
  });
}
