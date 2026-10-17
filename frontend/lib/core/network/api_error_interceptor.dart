import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';

/// dio 오류를 [AppException]으로 바꿔 `DioException.error`에 담는 인터셉터.
/// 원본 요청·응답 정보는 그대로 유지한다.
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.cancel || err.error is AppException) {
      handler.next(err);
      return;
    }

    final exception = _convert(err);
    if (exception is ApiException) {
      log(
        'API 오류 ${exception.errorCode.serverName} '
        '(${exception.httpStatus}): ${exception.developerMessage}',
        name: 'ApiErrorInterceptor',
      );
    }
    // reject가 아니라 next로 넘겨, 뒤에 추가될 인증 갱신·로깅 인터셉터의 onError도 실행되게 한다.
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }

  AppException _convert(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(NetworkFailureKind.timeout);
      case DioExceptionType.connectionError:
        return const NetworkException(NetworkFailureKind.connection);
      case DioExceptionType.badResponse:
        return _parseResponse(err.response);
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        // 응답은 받았지만 본문 디코딩에 실패한 경우(JSON이 아닌 5xx 등)도 서버 오류로 다룬다.
        if (err.response != null) {
          return _parseResponse(err.response);
        }
        return UnexpectedException(err);
    }
  }

  /// 본문이 없거나 JSON이 아니어도 실패하지 않도록 방어적으로 파싱한다.
  ApiException _parseResponse(Response<dynamic>? response) {
    final body = response?.data;
    String? errorCode;
    String? errorMessage;
    if (body is Map) {
      final rawCode = body['errorCode'];
      final rawMessage = body['errorMessage'];
      errorCode = rawCode is String ? rawCode : null;
      errorMessage = rawMessage is String ? rawMessage : null;
    }
    return ApiException(
      errorCode: ErrorCode.fromServerName(errorCode),
      httpStatus: response?.statusCode,
      developerMessage: errorMessage,
    );
  }
}
