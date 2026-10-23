import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:teeq/core/error/app_exception.dart';

const int _maxRetryCount = 2;
const List<Duration> _retryDelays = [
  Duration(milliseconds: 300),
  Duration(milliseconds: 600),
];

/// Riverpod provider 재시도 정책. `ProviderScope(retry: providerRetry)`로 연결한다.
/// 일시적 오류(네트워크 단절·타임아웃, 5xx)에 한해 최대 2회(300ms, 600ms) 재시도한다.
/// [ProviderException]과 [Error]는 재시도하지 않는다(이중 재시도 방지).
/// 인터셉터가 [AppException]을 `DioException.error`에 담아 던지므로, provider가 받는
/// 실제 오류는 [DioException]이다. 판단은 감싸진 원인으로 한다.
Duration? providerRetry(int retryCount, Object error) {
  if (error is ProviderException || error is Error) {
    return null;
  }
  if (retryCount >= _maxRetryCount) {
    return null;
  }
  final cause = error is DioException ? error.error : error;
  final isTransient =
      cause is NetworkException ||
      (cause is ApiException && (cause.httpStatus ?? 0) >= 500);
  return isTransient ? _retryDelays[retryCount] : null;
}
