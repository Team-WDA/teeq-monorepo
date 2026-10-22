import 'package:teeq/core/debug_console/network_log_entry.dart';

/// 기록된 요청을 터미널에서 재현할 수 있는 cURL 명령으로 바꾼다.
abstract final class CurlCommandBuilder {
  static String build(NetworkLogEntry entry) {
    final parts = ["curl -X ${entry.method} ${_quote(entry.url)}"];
    for (final header in entry.requestHeaders.entries) {
      parts.add('-H ${_quote('${header.key}: ${header.value}')}');
    }
    final body = entry.requestBody;
    if (body != null) {
      parts.add('--data-raw ${_quote(body.text)}');
    }
    final command = parts.join(' ');
    if (body != null && body.isTruncated) {
      return '$command\n# 본문이 잘려 일부만 포함됨 (전체 ${body.originalLength}글자)';
    }
    return command;
  }

  /// 작은따옴표로 감싸고 안쪽 작은따옴표는 `'\''`로 이스케이프한다.
  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
