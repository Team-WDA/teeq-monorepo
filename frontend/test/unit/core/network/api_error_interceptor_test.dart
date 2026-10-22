import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/network/api_error_interceptor.dart';

/// 지정한 응답을 돌려주거나 지정한 예외를 던지는 손수 만든 어댑터.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter.response(
    String body,
    int statusCode, {
    String contentType = 'application/json',
  }) : _responseBody = ResponseBody.fromString(
         body,
         statusCode,
         headers: {
           Headers.contentTypeHeader: [contentType],
         },
       ),
       _failure = null;

  _FakeHttpClientAdapter.failure(DioException Function(RequestOptions) failure)
    : _responseBody = null,
      _failure = failure;

  final ResponseBody? _responseBody;
  final DioException Function(RequestOptions)? _failure;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final failure = _failure;
    if (failure != null) {
      throw failure(options);
    }
    return _responseBody!;
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter, {AppLogger? logger}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(ApiErrorInterceptor(logger: logger ?? AppLogger()));
  return dio;
}

Future<DioException> _captureError(Dio dio) async {
  try {
    await dio.get<dynamic>('/test');
  } on DioException catch (error) {
    return error;
  }
  fail('DioException이 발생해야 한다');
}

void main() {
  test('알려진 errorCode는 ApiException으로 바뀌고 원본 응답이 유지된다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.response(
        jsonEncode({'errorCode': 'DUPLICATE_EMAIL', 'errorMessage': '상세'}),
        409,
      ),
    );

    final error = await _captureError(dio);
    final exception = error.error as ApiException;

    expect(exception.errorCode, ErrorCode.duplicateEmail);
    expect(exception.httpStatus, 409);
    expect(exception.developerMessage, '상세');
    expect(error.response?.statusCode, 409);
    expect(error.requestOptions.path, '/test');
  });

  test('모르는 errorCode는 unknown이다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.response(
        jsonEncode({'errorCode': 'BRAND_NEW', 'errorMessage': 'x'}),
        400,
      ),
    );

    final exception = (await _captureError(dio)).error as ApiException;
    expect(exception.errorCode, ErrorCode.unknown);
  });

  test('JSON이 아닌 500 본문도 ApiException(unknown)으로 바꾼다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.response(
        '<html>Bad Gateway</html>',
        500,
        contentType: 'text/html',
      ),
    );

    final exception = (await _captureError(dio)).error as ApiException;
    expect(exception.errorCode, ErrorCode.unknown);
    expect(exception.httpStatus, 500);
    expect(exception.developerMessage, isNull);
  });

  test('본문이 비어 있어도 ApiException으로 바꾼다', () async {
    final dio = _dioWith(_FakeHttpClientAdapter.response('', 503));

    final exception = (await _captureError(dio)).error as ApiException;
    expect(exception.errorCode, ErrorCode.unknown);
    expect(exception.httpStatus, 503);
  });

  test('본문이 Map이 아닌 JSON이어도 실패하지 않는다', () async {
    final dio = _dioWith(_FakeHttpClientAdapter.response('[1,2]', 400));

    final exception = (await _captureError(dio)).error as ApiException;
    expect(exception.errorCode, ErrorCode.unknown);
  });

  test('connectionTimeout은 NetworkException(timeout)이다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.failure(
        (options) => DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      ),
    );

    final exception = (await _captureError(dio)).error as NetworkException;
    expect(exception.kind, NetworkFailureKind.timeout);
  });

  test('connectionError는 NetworkException(connection)이다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.failure(
        (options) => DioException.connectionError(
          requestOptions: options,
          reason: '연결 실패',
        ),
      ),
    );

    final exception = (await _captureError(dio)).error as NetworkException;
    expect(exception.kind, NetworkFailureKind.connection);
  });

  test('cancel은 변환하지 않고 그대로 통과한다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.failure(
        (options) => DioException.requestCancelled(
          requestOptions: options,
          reason: '취소',
        ),
      ),
    );

    final error = await _captureError(dio);
    expect(error.type, DioExceptionType.cancel);
    expect(error.error, isNot(isA<AppException>()));
  });

  test('그 밖의 오류는 UnexpectedException이다', () async {
    final dio = _dioWith(
      _FakeHttpClientAdapter.failure(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('boom'),
        ),
      ),
    );

    final error = await _captureError(dio);
    expect(error.error, isA<UnexpectedException>());
  });

  test('4xx API 오류는 warning 로그로 남는다', () async {
    final entries = <AppLogEntry>[];
    final dio = _dioWith(
      _FakeHttpClientAdapter.response(
        jsonEncode({'errorCode': 'DUPLICATE_EMAIL', 'errorMessage': '상세'}),
        409,
      ),
      logger: AppLogger(onEntry: entries.add),
    );

    await _captureError(dio);

    expect(entries, hasLength(1));
    expect(entries.single.level, AppLogLevel.warning);
    expect(entries.single.name, 'ApiErrorInterceptor');
    expect(entries.single.message, contains('DUPLICATE_EMAIL'));
  });

  test('5xx API 오류는 error 로그로 남는다', () async {
    final entries = <AppLogEntry>[];
    final dio = _dioWith(
      _FakeHttpClientAdapter.response(
        jsonEncode({'errorCode': 'INTERNAL_SERVER_ERROR'}),
        500,
      ),
      logger: AppLogger(onEntry: entries.add),
    );

    await _captureError(dio);

    expect(entries.single.level, AppLogLevel.error);
  });
}
