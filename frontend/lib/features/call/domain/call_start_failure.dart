import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';

/// 통화 시작 요청이 실패한 이유 중 통화 화면이 직접 안내하는 것.
sealed class CallStartFailure {
  const CallStartFailure();
}

/// 오늘 쓸 수 있는 통화 시간이 부족하다.
final class CallStartDailyLimitExceeded extends CallStartFailure {
  const CallStartDailyLimitExceeded();
}

/// 서비스 전체 통화 한도가 찼다.
final class CallStartServiceLimitExceeded extends CallStartFailure {
  const CallStartServiceLimitExceeded();
}

/// 통화 연결을 만들지 못했다.
final class CallStartConnectionFailed extends CallStartFailure {
  const CallStartConnectionFailed();
}

/// 시작 요청 오류를 [CallStartFailure]로 바꾼다. null이면 중앙 `ErrorHandler`가 처리한다.
CallStartFailure? mapCallStartError(Object error) {
  final exception = AppException.from(error);
  if (exception is! ApiException) {
    return null;
  }
  return switch (exception.errorCode) {
    ErrorCode.callLimitInsufficient => const CallStartDailyLimitExceeded(),
    ErrorCode.callServiceLimitExceeded => const CallStartServiceLimitExceeded(),
    ErrorCode.aiServerUnavailable ||
    ErrorCode.callAlreadyInProgress => const CallStartConnectionFailed(),
    _ => null,
  };
}
