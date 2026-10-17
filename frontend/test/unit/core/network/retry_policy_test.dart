import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/network/retry_policy.dart';

void main() {
  const serverError = ApiException(
    errorCode: ErrorCode.internalServerError,
    httpStatus: 500,
  );
  const networkError = NetworkException(NetworkFailureKind.connection);

  test('일시적 오류는 최대 2회, 300ms 후 600ms 간격으로 재시도한다', () {
    for (final error in [serverError, networkError]) {
      expect(providerRetry(0, error), const Duration(milliseconds: 300));
      expect(providerRetry(1, error), const Duration(milliseconds: 600));
      expect(providerRetry(2, error), isNull);
    }
  });

  test('4xx ApiException은 재시도하지 않는다', () {
    const clientError = ApiException(
      errorCode: ErrorCode.invalidRequest,
      httpStatus: 400,
    );
    expect(providerRetry(0, clientError), isNull);
  });

  test('httpStatus가 없는 ApiException은 재시도하지 않는다', () {
    const noStatus = ApiException(
      errorCode: ErrorCode.unknown,
      httpStatus: null,
    );
    expect(providerRetry(0, noStatus), isNull);
  });

  test('인터셉터가 감싼 DioException도 원인으로 판단해 재시도한다', () {
    for (final cause in [serverError, networkError]) {
      final wrapped = DioException(
        requestOptions: RequestOptions(),
        error: cause,
      );
      expect(providerRetry(0, wrapped), const Duration(milliseconds: 300));
      expect(providerRetry(1, wrapped), const Duration(milliseconds: 600));
      expect(providerRetry(2, wrapped), isNull);
    }
  });

  test('감싼 원인이 4xx이거나 없는 DioException은 재시도하지 않는다', () {
    const clientError = ApiException(
      errorCode: ErrorCode.invalidRequest,
      httpStatus: 400,
    );
    expect(
      providerRetry(
        0,
        DioException(requestOptions: RequestOptions(), error: clientError),
      ),
      isNull,
    );
    expect(
      providerRetry(0, DioException(requestOptions: RequestOptions())),
      isNull,
    );
  });

  test('UnexpectedException은 재시도하지 않는다', () {
    expect(providerRetry(0, const UnexpectedException('x')), isNull);
  });

  test('Error는 재시도하지 않는다', () {
    expect(providerRetry(0, StateError('boom')), isNull);
  });

  test('ProviderException은 재시도하지 않는다', () async {
    final provider = FutureProvider<int>((ref) => throw serverError);
    final container = ProviderContainer(retry: (_, _) => null);
    addTearDown(container.dispose);

    Object? caught;
    try {
      container.read(provider).requireValue;
    } catch (error) {
      caught = error;
    }
    expect(caught, isA<ProviderException>());
    expect(providerRetry(0, caught!), isNull);
  });
}
