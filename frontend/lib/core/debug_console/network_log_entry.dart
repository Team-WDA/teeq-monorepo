import 'package:teeq/core/debug_console/body_preview.dart';

/// 네트워크 호출 한 건의 진행 결과.
enum NetworkLogOutcome { pending, success, failure }

/// 디버그 콘솔의 네트워크 호출 기록 한 건. 요청을 보낼 때 만들고 응답이나 오류가 오면 완료본으로 바꾼다.
final class NetworkLogEntry {
  const NetworkLogEntry({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.duration,
    this.errorDescription,
  });

  final String id;
  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final BodyPreview? requestBody;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final BodyPreview? responseBody;

  /// 응답이나 오류가 올 때까지는 null이다.
  final Duration? duration;
  final String? errorDescription;

  NetworkLogOutcome get outcome {
    if (duration == null) {
      return NetworkLogOutcome.pending;
    }
    final code = statusCode;
    final isSuccessStatus = code != null && code >= 200 && code <= 299;
    return isSuccessStatus && errorDescription == null
        ? NetworkLogOutcome.success
        : NetworkLogOutcome.failure;
  }

  NetworkLogEntry copyWith({
    Map<String, String>? requestHeaders,
    BodyPreview? requestBody,
    int? statusCode,
    Map<String, String>? responseHeaders,
    BodyPreview? responseBody,
    Duration? duration,
    String? errorDescription,
  }) {
    return NetworkLogEntry(
      id: id,
      startedAt: startedAt,
      method: method,
      url: url,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      duration: duration ?? this.duration,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }
}
