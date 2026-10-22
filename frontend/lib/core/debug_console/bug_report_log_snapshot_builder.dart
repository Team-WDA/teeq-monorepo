import 'dart:convert';

import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';

/// 버그 제보 한 번에 실어 보내는 로그 종류별 최대 건수.
const int bugReportMaxLogEntryCount = 100;

/// 서버가 받아 주는 에러 로그와 네트워크 기록의 합계 최대 바이트(5 MiB).
const int bugReportMaxLogBytes = 5 * 1024 * 1024;

/// 서버가 로그를 다시 직렬화해 크기를 재므로 오차를 감안해 남겨 두는 여유(64 KiB).
const int bugReportLogSafetyMarginBytes = 64 * 1024;

/// 실제로 채울 수 있는 로그 바이트 예산.
const int bugReportLogByteBudget =
    bugReportMaxLogBytes - bugReportLogSafetyMarginBytes;

/// 버그 제보에 실을 로그 묶음. 목록은 오래된 것에서 최신 순이고, 키는 서버 요청 계약을 따른다.
final class BugReportLogSnapshot {
  const BugReportLogSnapshot({
    required this.errorLogs,
    required this.networkLogs,
    required this.omittedErrorLogCount,
    required this.omittedNetworkLogCount,
  });

  final List<Map<String, Object?>> errorLogs;
  final List<Map<String, Object?>> networkLogs;

  /// 건수나 용량 제한 때문에 싣지 못한 에러 로그 수.
  final int omittedErrorLogCount;

  /// 건수나 용량 제한 때문에 싣지 못한 네트워크 기록 수.
  final int omittedNetworkLogCount;
}

/// [state]에서 최신 항목을 우선해 종류별 [bugReportMaxLogEntryCount]건,
/// 합계 [bugReportLogByteBudget] 바이트 안으로 로그를 고른다.
/// 에러 로그를 먼저 담고 남은 용량에 네트워크 기록을 채운다. 헤더를 포함해 가리지 않고 그대로 담는다.
BugReportLogSnapshot buildBugReportLogSnapshot(DebugConsoleState state) {
  // 두 목록의 여는·닫는 대괄호 4바이트는 항목과 무관하게 항상 든다.
  const listBracketBytes = 4;
  final errorSelection = _selectNewest(
    state.errorLogs.map(_serializeErrorLog).toList(),
    remainingBytes: bugReportLogByteBudget - listBracketBytes,
  );
  final networkSelection = _selectNewest(
    state.networkEntries.map(_serializeNetworkLog).toList(),
    remainingBytes:
        bugReportLogByteBudget - listBracketBytes - errorSelection.usedBytes,
  );
  return BugReportLogSnapshot(
    errorLogs: errorSelection.entries,
    networkLogs: networkSelection.entries,
    omittedErrorLogCount:
        state.errorLogs.length - errorSelection.entries.length,
    omittedNetworkLogCount:
        state.networkEntries.length - networkSelection.entries.length,
  );
}

final class _Selection {
  const _Selection(this.entries, this.usedBytes);

  final List<Map<String, Object?>> entries;
  final int usedBytes;
}

/// 최신 항목부터 건수와 [remainingBytes]가 허용하는 만큼 연속으로 담고 시간순으로 돌려준다.
/// 항목마다 UTF-8 바이트 길이에 쉼표 1바이트(첫 항목 제외)를 센다.
_Selection _selectNewest(
  List<Map<String, Object?>> chronologicalEntries, {
  required int remainingBytes,
}) {
  final newestFirst = <Map<String, Object?>>[];
  var usedBytes = 0;
  for (final entry in chronologicalEntries.reversed) {
    if (newestFirst.length >= bugReportMaxLogEntryCount) {
      break;
    }
    final commaBytes = newestFirst.isEmpty ? 0 : 1;
    final entryBytes = utf8.encode(jsonEncode(entry)).length + commaBytes;
    if (usedBytes + entryBytes > remainingBytes) {
      break;
    }
    usedBytes += entryBytes;
    newestFirst.add(entry);
  }
  return _Selection(List.unmodifiable(newestFirst.reversed), usedBytes);
}

/// 시각은 UTC ISO-8601, level은 enum 이름을 대문자로 보낸다(예: `ERROR`, 서버 제한 20자 이하).
Map<String, Object?> _serializeErrorLog(AppLogEntry entry) => {
  'timestamp': entry.timestamp.toUtc().toIso8601String(),
  'level': _clamp(entry.level.name.toUpperCase(), _maxLevelLength),
  'name': _clamp(entry.name, _maxLogNameLength),
  'message': _clamp(entry.message, _maxTextLength),
  'errorDescription': _clampNullable(entry.errorDescription, _maxTextLength),
  'stackTraceText': _clampNullable(entry.stackTraceText, _maxTextLength),
};

/// 본문이 서버 한도에 걸려 잘리면 `*Truncated`를 true로 올린다.
Map<String, Object?> _serializeNetworkLog(NetworkLogEntry entry) {
  final requestText = entry.requestBody?.text;
  final responseText = entry.responseBody?.text;
  return {
    'startedAt': entry.startedAt.toUtc().toIso8601String(),
    'method': _clamp(entry.method, _maxMethodLength),
    'url': _clamp(entry.url, _maxUrlLength),
    'requestHeaders': _clampHeaders(entry.requestHeaders),
    'requestBody': _clampNullable(requestText, _maxTextLength),
    'requestBodyTruncated':
        (entry.requestBody?.isTruncated ?? false) ||
        _isCut(requestText, _maxTextLength),
    'statusCode': entry.statusCode,
    'responseHeaders': _clampHeaders(entry.responseHeaders),
    'responseBody': _clampNullable(responseText, _maxTextLength),
    'responseBodyTruncated':
        (entry.responseBody?.isTruncated ?? false) ||
        _isCut(responseText, _maxTextLength),
    'durationMilliseconds': entry.duration?.inMilliseconds,
    'errorDescription': _clampNullable(entry.errorDescription, _maxTextLength),
  };
}

// 서버 요청 DTO의 @Size 한도. 하나라도 넘으면 제보 전체가 거부되므로 보내기 전에 자른다.
const int _maxLevelLength = 20;
const int _maxLogNameLength = 200;
const int _maxMethodLength = 10;
const int _maxUrlLength = 2048;
const int _maxTextLength = 102400;
const int _maxHeaderCount = 100;

/// [value]를 UTF-16 코드 유닛 [maxLength]까지로 자른다(서버 @Size와 같은 단위).
/// 자르는 자리가 서로게이트 쌍의 가운데면 앞 글자를 하나 더 버려 깨진 문자가 남지 않게 한다.
String _clamp(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  final lastUnit = value.codeUnitAt(maxLength - 1);
  final endsOnHighSurrogate = lastUnit >= 0xD800 && lastUnit <= 0xDBFF;
  return value.substring(0, endsOnHighSurrogate ? maxLength - 1 : maxLength);
}

String? _clampNullable(String? value, int maxLength) =>
    value == null ? null : _clamp(value, maxLength);

/// 앞에서부터 [_maxHeaderCount]개만 남긴다.
Map<String, String> _clampHeaders(Map<String, String> headers) =>
    Map.fromEntries(headers.entries.take(_maxHeaderCount));

bool _isCut(String? text, int maxLength) =>
    text != null && text.length > maxLength;
