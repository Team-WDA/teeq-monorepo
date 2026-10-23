import 'package:dio/dio.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_messages.dart';

/// 앱 전체에서 쓰는 정규화된 예외. 사용자에게는 [userMessage]만 보여 준다.
sealed class AppException implements Exception {
  const AppException();

  /// 사용자에게 보여 줄 한국어 문구.
  String get userMessage;

  /// 어떤 오류 객체든 [AppException]으로 정규화한다.
  /// [DioException]은 인터셉터가 담아 둔 [AppException]을 꺼내고, 없으면 유형으로 판단한다.
  factory AppException.from(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is AppException) {
        return wrapped;
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const NetworkException(
          NetworkFailureKind.timeout,
        ),
        DioExceptionType.connectionError => const NetworkException(
          NetworkFailureKind.connection,
        ),
        _ => UnexpectedException(error),
      };
    }
    return UnexpectedException(error);
  }
}

/// 서버가 `{errorCode, errorMessage}`로 응답한 오류.
final class ApiException extends AppException {
  const ApiException({
    required this.errorCode,
    required this.httpStatus,
    this.developerMessage,
  });

  final ErrorCode errorCode;
  final int? httpStatus;

  /// 서버 `errorMessage`. 로그 전용이며 사용자에게 절대 보여 주지 않는다.
  final String? developerMessage;

  @override
  String get userMessage => errorCode.userMessage;

  @override
  String toString() =>
      'ApiException(errorCode: ${errorCode.serverName}, httpStatus: $httpStatus)';
}

/// 네트워크 실패의 종류.
enum NetworkFailureKind { connection, timeout }

/// 연결 실패 또는 타임아웃.
final class NetworkException extends AppException {
  const NetworkException(this.kind);

  final NetworkFailureKind kind;

  @override
  String get userMessage => networkErrorMessage;

  @override
  String toString() => 'NetworkException(kind: ${kind.name})';
}

/// 분류할 수 없는 예상 밖 오류.
final class UnexpectedException extends AppException {
  const UnexpectedException(this.cause);

  /// 로그 전용 원인 객체.
  final Object cause;

  @override
  String get userMessage => unknownErrorMessage;

  @override
  String toString() => 'UnexpectedException(cause: $cause)';
}

/// 탈퇴 중 Apple 연동 해제(재인증·revoke)에 실패했다. 탈퇴는 진행하지 않는다.
final class AppleConnectionRevokeFailedException extends AppException {
  const AppleConnectionRevokeFailedException([this.cause]);

  /// 로그 전용 원인 객체.
  final Object? cause;

  @override
  String get userMessage => appleConnectionRevokeFailedMessage;

  @override
  String toString() => 'AppleConnectionRevokeFailedException(cause: $cause)';
}

/// 이메일 또는 비밀번호가 틀려 Firebase 로그인에 실패했다.
final class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([this.cause]);

  /// 로그 전용 원인 객체.
  final Object? cause;

  @override
  String get userMessage => invalidCredentialsMessage;

  @override
  String toString() => 'InvalidCredentialsException(cause: $cause)';
}

/// 이미 가입된 이메일이라 Firebase 계정을 만들 수 없다.
final class EmailAlreadyInUseException extends AppException {
  const EmailAlreadyInUseException([this.cause]);

  /// 로그 전용 원인 객체.
  final Object? cause;

  @override
  String get userMessage => emailAlreadyInUseMessage;

  @override
  String toString() => 'EmailAlreadyInUseException(cause: $cause)';
}

/// 비밀번호 변경 중 입력한 현재 비밀번호가 틀렸다. 화면이 현재 비밀번호 칸의 인라인 오류로 보여 준다.
final class InvalidCurrentPasswordException extends AppException {
  const InvalidCurrentPasswordException([this.cause]);

  /// 로그 전용 원인 객체.
  final Object? cause;

  @override
  String get userMessage => invalidCurrentPasswordMessage;

  @override
  String toString() => 'InvalidCurrentPasswordException(cause: $cause)';
}

/// Firebase가 로그인 시도 과다로 잠시 요청을 막았다.
final class TooManyAttemptsException extends AppException {
  const TooManyAttemptsException([this.cause]);

  /// 로그 전용 원인 객체.
  final Object? cause;

  @override
  String get userMessage => tooManyAttemptsMessage;

  @override
  String toString() => 'TooManyAttemptsException(cause: $cause)';
}
