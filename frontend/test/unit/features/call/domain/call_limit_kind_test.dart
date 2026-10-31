import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';

void main() {
  group('CallLimitKind.fromServerName', () {
    test('서버 이름을 한도 종류로 바꾼다', () {
      expect(CallLimitKind.fromServerName('PER_CALL'), CallLimitKind.perCall);
      expect(CallLimitKind.fromServerName('PER_DAY'), CallLimitKind.perDay);
      expect(
        CallLimitKind.fromServerName('WHOLE_SERVICE'),
        CallLimitKind.wholeService,
      );
    });

    test('소문자나 null은 null이다', () {
      expect(CallLimitKind.fromServerName('per_day'), isNull);
      expect(CallLimitKind.fromServerName(null), isNull);
    });
  });
}
