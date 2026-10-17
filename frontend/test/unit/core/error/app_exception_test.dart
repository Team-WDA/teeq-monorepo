import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_messages.dart';

DioException _dioException(DioExceptionType type, {Object? error}) =>
    DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
      error: error,
    );

void main() {
  group('AppException.from', () {
    test('AppException은 그대로 반환한다', () {
      const exception = NetworkException(NetworkFailureKind.timeout);
      expect(AppException.from(exception), same(exception));
    });

    test('DioException.error가 AppException이면 꺼낸다', () {
      const wrapped = ApiException(
        errorCode: ErrorCode.expiredToken,
        httpStatus: 401,
      );
      final result = AppException.from(
        _dioException(DioExceptionType.badResponse, error: wrapped),
      );
      expect(result, same(wrapped));
    });

    test('래핑이 없으면 DioException 유형으로 판단한다', () {
      final timeout = AppException.from(
        _dioException(DioExceptionType.receiveTimeout),
      );
      expect(timeout, isA<NetworkException>());
      expect((timeout as NetworkException).kind, NetworkFailureKind.timeout);

      final connection = AppException.from(
        _dioException(DioExceptionType.connectionError),
      );
      expect(
        (connection as NetworkException).kind,
        NetworkFailureKind.connection,
      );

      expect(
        AppException.from(_dioException(DioExceptionType.unknown)),
        isA<UnexpectedException>(),
      );
    });

    test('그 밖의 객체는 UnexpectedException이다', () {
      final result = AppException.from(StateError('boom'));
      expect(result, isA<UnexpectedException>());
      expect(result.userMessage, unknownErrorMessage);
    });
  });

  test('userMessage는 developerMessage를 포함하지 않는다', () {
    const developerMessage = '서버 내부 상세 메시지 SECRET-DETAIL';
    for (final code in ErrorCode.values) {
      final exception = ApiException(
        errorCode: code,
        httpStatus: 400,
        developerMessage: developerMessage,
      );
      expect(exception.userMessage, isNot(contains(developerMessage)));
      expect(exception.toString(), isNot(contains(developerMessage)));
    }
  });

  test('NetworkException은 네트워크 문구를 보여 준다', () {
    expect(
      const NetworkException(NetworkFailureKind.connection).userMessage,
      networkErrorMessage,
    );
  });
}
