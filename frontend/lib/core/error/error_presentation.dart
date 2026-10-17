import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';

/// 오류를 사용자에게 보여 주는 방식.
enum ErrorPresentation {
  /// 화면을 유지한 채 토스트로 알린다.
  toast,

  /// 오류 페이지로 이동한다.
  errorPage,

  /// 로그인 상태를 해제하고 로그인으로 보낸다.
  authentication,
}

const Set<ErrorCode> _authenticationErrorCodes = {
  ErrorCode.unauthenticated,
  ErrorCode.expiredToken,
  ErrorCode.invalidRefreshToken,
};

/// 오류를 표시 방식으로 분류하는 순수 함수.
/// 우선순위: 인증 오류 > 오류 페이지 > 토스트.
/// [blocking]은 앱 시작·초기 로딩처럼 화면을 이어 갈 수 없는 실패일 때 true로 넘긴다.
ErrorPresentation classify(AppException exception, {bool blocking = false}) {
  if (exception is ApiException &&
      _authenticationErrorCodes.contains(exception.errorCode)) {
    return ErrorPresentation.authentication;
  }
  if (blocking) {
    return ErrorPresentation.errorPage;
  }
  return switch (exception) {
    NetworkException() => ErrorPresentation.errorPage,
    ApiException(errorCode: ErrorCode.internalServerError) =>
      ErrorPresentation.errorPage,
    _ => ErrorPresentation.toast,
  };
}
