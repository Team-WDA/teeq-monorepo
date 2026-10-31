import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/features/call/domain/call_start_failure.dart';

ApiException _api(ErrorCode errorCode) =>
    ApiException(errorCode: errorCode, httpStatus: 400);

void main() {
  group('mapCallStartError', () {
    test('일일 한도 부족은 CallStartDailyLimitExceeded다', () {
      expect(
        mapCallStartError(_api(ErrorCode.callLimitInsufficient)),
        isA<CallStartDailyLimitExceeded>(),
      );
    });

    test('서비스 전체 한도 초과는 CallStartServiceLimitExceeded다', () {
      expect(
        mapCallStartError(_api(ErrorCode.callServiceLimitExceeded)),
        isA<CallStartServiceLimitExceeded>(),
      );
    });

    test('AI 서버 장애와 진행 중 통화는 CallStartConnectionFailed다', () {
      expect(
        mapCallStartError(_api(ErrorCode.aiServerUnavailable)),
        isA<CallStartConnectionFailed>(),
      );
      expect(
        mapCallStartError(_api(ErrorCode.callAlreadyInProgress)),
        isA<CallStartConnectionFailed>(),
      );
    });

    test('그 외 코드, 네트워크 예외, 일반 예외는 null이다', () {
      expect(mapCallStartError(_api(ErrorCode.unknown)), isNull);
      expect(
        mapCallStartError(const NetworkException(NetworkFailureKind.timeout)),
        isNull,
      );
      expect(mapCallStartError(StateError('x')), isNull);
    });
  });
}
