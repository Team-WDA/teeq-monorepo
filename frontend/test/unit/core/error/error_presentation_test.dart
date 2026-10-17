import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_presentation.dart';

ApiException _api(ErrorCode code, {int status = 400}) =>
    ApiException(errorCode: code, httpStatus: status);

void main() {
  group('classify', () {
    test('인증 오류 코드 3개는 authentication', () {
      for (final code in [
        ErrorCode.unauthenticated,
        ErrorCode.expiredToken,
        ErrorCode.invalidRefreshToken,
      ]) {
        expect(
          classify(_api(code, status: 401)),
          ErrorPresentation.authentication,
        );
      }
    });

    test('INTERNAL_SERVER_ERROR와 네트워크 오류는 errorPage', () {
      expect(
        classify(_api(ErrorCode.internalServerError, status: 500)),
        ErrorPresentation.errorPage,
      );
      for (final kind in NetworkFailureKind.values) {
        expect(classify(NetworkException(kind)), ErrorPresentation.errorPage);
      }
    });

    test('로그인 화면 401(invalidCredentials 등)은 toast', () {
      for (final code in [
        ErrorCode.invalidCredentials,
        ErrorCode.socialTokenInvalid,
        ErrorCode.loginMethodMismatch,
      ]) {
        expect(classify(_api(code, status: 401)), ErrorPresentation.toast);
      }
    });

    test('나머지 코드와 예상 밖 오류는 toast', () {
      final handled = {
        ErrorCode.unauthenticated,
        ErrorCode.expiredToken,
        ErrorCode.invalidRefreshToken,
        ErrorCode.internalServerError,
      };
      for (final code in ErrorCode.values.where((c) => !handled.contains(c))) {
        expect(classify(_api(code)), ErrorPresentation.toast, reason: '$code');
      }
      expect(classify(const UnexpectedException('x')), ErrorPresentation.toast);
    });

    test('blocking이면 errorPage, 단 인증 오류가 우선', () {
      expect(
        classify(_api(ErrorCode.invalidRequest), blocking: true),
        ErrorPresentation.errorPage,
      );
      expect(
        classify(const UnexpectedException('x'), blocking: true),
        ErrorPresentation.errorPage,
      );
      expect(
        classify(_api(ErrorCode.expiredToken, status: 401), blocking: true),
        ErrorPresentation.authentication,
      );
    });
  });
}
