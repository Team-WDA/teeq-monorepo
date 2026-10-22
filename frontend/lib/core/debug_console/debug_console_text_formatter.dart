import 'package:teeq/core/debug_console/body_preview.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';

/// 디버그 콘솔 항목을 클립보드에 복사할 문자열로 바꾼다.
abstract final class DebugConsoleTextFormatter {
  static const String _entrySeparator = '\n\n';

  static String networkEntry(NetworkLogEntry entry) {
    final lines = <String>[
      '[${entry.startedAt.toIso8601String()}] ${entry.method} ${entry.url}',
      statusLine(entry),
      '요청 헤더:',
      ..._headerLines(entry.requestHeaders),
      if (entry.requestBody != null) ...[
        '요청 본문:',
        bodyText(entry.requestBody!),
      ],
      '응답 헤더:',
      ..._headerLines(entry.responseHeaders),
      if (entry.responseBody != null) ...[
        '응답 본문:',
        bodyText(entry.responseBody!),
      ],
      if (entry.errorDescription != null) '오류: ${entry.errorDescription}',
    ];
    return lines.join('\n');
  }

  static String networkEntries(List<NetworkLogEntry> entries) =>
      entries.map(networkEntry).join(_entrySeparator);

  static String applicationLog(AppLogEntry entry) {
    final lines = <String>[
      '[${entry.timestamp.toIso8601String()}] '
          '[${entry.level.name.toUpperCase()}] ${entry.name}: ${entry.message}',
      if (entry.errorDescription != null) '오류: ${entry.errorDescription}',
      if (entry.stackTraceText != null) '스택:\n${entry.stackTraceText}',
    ];
    return lines.join('\n');
  }

  static String applicationLogs(List<AppLogEntry> entries) =>
      entries.map(applicationLog).join(_entrySeparator);

  static String applicationInformation({
    required String? appVersion,
    required String apiBaseUrl,
    required String operatingSystem,
    required String route,
  }) {
    return [
      '앱 버전: ${appVersion ?? '알 수 없음'}',
      'API 서버: $apiBaseUrl',
      '운영체제: $operatingSystem',
      '현재 라우트: $route',
    ].join('\n');
  }

  /// 상태 코드와 소요 시간을 한 줄로 보여 준다.
  static String statusLine(NetworkLogEntry entry) {
    final status = entry.statusCode?.toString() ?? '응답 없음';
    final duration = entry.duration;
    final elapsed = duration == null ? '대기 중' : '${duration.inMilliseconds}ms';
    return '상태: $status ($elapsed)';
  }

  static Iterable<String> _headerLines(Map<String, String> headers) =>
      headers.entries.map((header) => '  ${header.key}: ${header.value}');

  /// 헤더를 한 줄에 하나씩 보여 준다. 비어 있으면 `(없음)`.
  static String headersText(Map<String, String> headers) => headers.isEmpty
      ? '(없음)'
      : headers.entries
            .map((header) => '${header.key}: ${header.value}')
            .join('\n');

  /// 본문을 보여 준다. 잘린 본문에는 잘림 표시와 전체 글자 수를 덧붙인다.
  static String bodyText(BodyPreview body) => body.isTruncated
      ? '${body.text}\n…(잘림, 전체 ${body.originalLength}글자)'
      : body.text;
}
