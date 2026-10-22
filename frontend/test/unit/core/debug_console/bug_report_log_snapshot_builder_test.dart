import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/body_preview.dart';
import 'package:teeq/core/debug_console/bug_report_log_snapshot_builder.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

AppLogEntry _errorLog(int index) => AppLogEntry(
  timestamp: DateTime.utc(2026, 10, 22).add(Duration(seconds: index)),
  level: AppLogLevel.error,
  name: 'Logger$index',
  message: 'message $index',
);

NetworkLogEntry _networkEntry(
  int index, {
  String? responseText,
  Map<String, String> requestHeaders = const {},
}) => NetworkLogEntry(
  id: '$index',
  startedAt: DateTime.utc(2026, 10, 22).add(Duration(seconds: index)),
  method: 'GET',
  url: 'https://api.example.test/$index',
  requestHeaders: requestHeaders,
  responseBody: responseText == null
      ? null
      : BodyPreview(
          text: responseText,
          isTruncated: false,
          originalLength: responseText.length,
        ),
  statusCode: 200,
  duration: const Duration(milliseconds: 12),
);

void main() {
  test('build_keepsNewestHundredPerKind', () {
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        errorLogs: List.generate(150, _errorLog),
        networkEntries: List.generate(150, _networkEntry),
      ),
    );

    expect(snapshot.errorLogs, hasLength(100));
    expect(snapshot.networkLogs, hasLength(100));
    expect(snapshot.omittedErrorLogCount, 50);
    expect(snapshot.omittedNetworkLogCount, 50);
    expect(snapshot.errorLogs.first['name'], 'Logger50');
    expect(snapshot.networkLogs.first['url'], 'https://api.example.test/50');
  });

  test('build_fillsErrorLogsFirstThenNetworkWithinFiveMegabytes', () {
    final bigBody = 'a' * (100 * 1024);
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        errorLogs: List.generate(3, _errorLog),
        networkEntries: List.generate(
          100,
          (index) => _networkEntry(index, responseText: bigBody),
        ),
      ),
    );

    expect(snapshot.errorLogs, hasLength(3));
    expect(snapshot.networkLogs.length, lessThan(100));
    expect(snapshot.networkLogs.length, greaterThan(0));
    expect(snapshot.omittedNetworkLogCount, 100 - snapshot.networkLogs.length);
    // 오래된 항목부터 빠지므로 남은 것의 마지막은 가장 최신이다.
    expect(snapshot.networkLogs.last['url'], 'https://api.example.test/99');
    final totalBytes =
        utf8.encode(jsonEncode(snapshot.errorLogs)).length +
        utf8.encode(jsonEncode(snapshot.networkLogs)).length;
    expect(totalBytes, lessThanOrEqualTo(bugReportLogByteBudget));
    expect(bugReportLogByteBudget, lessThan(bugReportMaxLogBytes));
  });

  test('build_outputsChronologicalOrder', () {
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        errorLogs: List.generate(5, _errorLog),
        networkEntries: List.generate(5, _networkEntry),
      ),
    );

    expect(snapshot.errorLogs.map((log) => log['name']), [
      'Logger0',
      'Logger1',
      'Logger2',
      'Logger3',
      'Logger4',
    ]);
    expect(snapshot.networkLogs.first['url'], 'https://api.example.test/0');
    expect(snapshot.networkLogs.last['url'], 'https://api.example.test/4');
  });

  test('build_doesNotMaskHeaders', () {
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        networkEntries: [
          _networkEntry(
            0,
            requestHeaders: const {'Authorization': 'Bearer secret-token'},
          ),
        ],
      ),
    );

    final headers =
        snapshot.networkLogs.single['requestHeaders']! as Map<String, String>;
    expect(headers['Authorization'], 'Bearer secret-token');
  });

  test('build_emptyState_returnsEmptyLists', () {
    final snapshot = buildBugReportLogSnapshot(const DebugConsoleState());

    expect(snapshot.errorLogs, isEmpty);
    expect(snapshot.networkLogs, isEmpty);
    expect(snapshot.omittedErrorLogCount, 0);
    expect(snapshot.omittedNetworkLogCount, 0);
  });

  test('build_serializesFieldsPerWireContract', () {
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        errorLogs: [
          AppLogEntry(
            timestamp: DateTime.utc(2026, 10, 22, 1, 2, 3),
            level: AppLogLevel.warning,
            name: 'ErrorHandler',
            message: 'failed',
            errorDescription: 'boom',
            stackTraceText: '#0 main',
          ),
        ],
        networkEntries: [
          NetworkLogEntry(
            id: '1',
            startedAt: DateTime.utc(2026, 10, 22, 1, 2, 3),
            method: 'POST',
            url: 'https://api.example.test/a',
            requestHeaders: const {'Accept': 'application/json'},
            requestBody: const BodyPreview(
              text: '{}',
              isTruncated: true,
              originalLength: 500000,
            ),
            statusCode: 500,
            responseHeaders: const {'X-Trace': 'abc'},
            responseBody: const BodyPreview(
              text: 'err',
              isTruncated: false,
              originalLength: 3,
            ),
            duration: const Duration(milliseconds: 250),
            errorDescription: 'server error',
          ),
        ],
      ),
    );

    final errorLog = snapshot.errorLogs.single;
    expect(errorLog.keys.toSet(), {
      'timestamp',
      'level',
      'name',
      'message',
      'errorDescription',
      'stackTraceText',
    });
    expect(errorLog['timestamp'], '2026-10-22T01:02:03.000Z');
    expect(errorLog['level'], 'WARNING');
    expect(errorLog['errorDescription'], 'boom');
    expect(errorLog['stackTraceText'], '#0 main');

    final networkLog = snapshot.networkLogs.single;
    expect(networkLog.keys.toSet(), {
      'startedAt',
      'method',
      'url',
      'requestHeaders',
      'requestBody',
      'requestBodyTruncated',
      'statusCode',
      'responseHeaders',
      'responseBody',
      'responseBodyTruncated',
      'durationMilliseconds',
      'errorDescription',
    });
    expect(networkLog['startedAt'], '2026-10-22T01:02:03.000Z');
    expect(networkLog['requestBody'], '{}');
    expect(networkLog['requestBodyTruncated'], true);
    expect(networkLog['responseBody'], 'err');
    expect(networkLog['responseBodyTruncated'], false);
    expect(networkLog['statusCode'], 500);
    expect(networkLog['durationMilliseconds'], 250);
    expect(networkLog['errorDescription'], 'server error');
  });

  test('build_pendingEntry_serializesNullableFieldsAsNull', () {
    final snapshot = buildBugReportLogSnapshot(
      DebugConsoleState(
        networkEntries: [
          NetworkLogEntry(
            id: '1',
            startedAt: DateTime.utc(2026, 10, 22),
            method: 'GET',
            url: 'https://api.example.test/a',
            requestHeaders: const {},
          ),
        ],
      ),
    );

    final networkLog = snapshot.networkLogs.single;
    expect(networkLog['requestBody'], isNull);
    expect(networkLog['requestBodyTruncated'], false);
    expect(networkLog['statusCode'], isNull);
    expect(networkLog['durationMilliseconds'], isNull);
    expect(networkLog['errorDescription'], isNull);
  });

  group('clamps to server limits', () {
    test('build_longUrl_clampedTo2048', () {
      final snapshot = buildBugReportLogSnapshot(
        DebugConsoleState(
          networkEntries: [
            NetworkLogEntry(
              id: '1',
              startedAt: DateTime.utc(2026, 10, 22),
              method: 'GET',
              url: 'u' * 3000,
              requestHeaders: const {},
            ),
          ],
        ),
      );

      expect((snapshot.networkLogs.single['url']! as String).length, 2048);
    });

    test('build_manyHeaders_keepsFirstHundred', () {
      final headers = {for (var i = 0; i < 150; i++) 'h$i': 'v'};
      final snapshot = buildBugReportLogSnapshot(
        DebugConsoleState(
          networkEntries: [
            NetworkLogEntry(
              id: '1',
              startedAt: DateTime.utc(2026, 10, 22),
              method: 'GET',
              url: 'https://api.example.test/a',
              requestHeaders: headers,
              responseHeaders: headers,
            ),
          ],
        ),
      );

      final networkLog = snapshot.networkLogs.single;
      final requestHeaders =
          networkLog['requestHeaders']! as Map<String, String>;
      final responseHeaders =
          networkLog['responseHeaders']! as Map<String, String>;
      expect(requestHeaders, hasLength(100));
      expect(requestHeaders.keys.first, 'h0');
      expect(requestHeaders.keys.last, 'h99');
      expect(responseHeaders, hasLength(100));
    });

    test('build_longErrorMessage_clampedTo102400', () {
      final snapshot = buildBugReportLogSnapshot(
        DebugConsoleState(
          errorLogs: [
            AppLogEntry(
              timestamp: DateTime.utc(2026, 10, 22),
              level: AppLogLevel.error,
              name: 'n' * 300,
              message: 'm' * 200000,
            ),
          ],
        ),
      );

      final errorLog = snapshot.errorLogs.single;
      expect((errorLog['message']! as String).length, 102400);
      expect((errorLog['name']! as String).length, 200);
    });

    test('build_cutBody_setsTruncatedFlag', () {
      final text = 'b' * 102401;
      final snapshot = buildBugReportLogSnapshot(
        DebugConsoleState(
          networkEntries: [
            NetworkLogEntry(
              id: '1',
              startedAt: DateTime.utc(2026, 10, 22),
              method: 'POST',
              url: 'https://api.example.test/a',
              requestHeaders: const {},
              requestBody: BodyPreview(
                text: text,
                isTruncated: false,
                originalLength: text.length,
              ),
            ),
          ],
        ),
      );

      final networkLog = snapshot.networkLogs.single;
      expect((networkLog['requestBody']! as String).length, 102400);
      expect(networkLog['requestBodyTruncated'], true);
      expect(networkLog['responseBodyTruncated'], false);
    });

    test('build_emojiAtCut_leavesNoLoneSurrogate', () {
      // 'a' 102399개 뒤에 이모지(코드 유닛 2개)라 한도 경계에서 쌍이 갈라진다.
      final message = '${'a' * 102399}\u{1F600}';
      final snapshot = buildBugReportLogSnapshot(
        DebugConsoleState(
          errorLogs: [
            AppLogEntry(
              timestamp: DateTime.utc(2026, 10, 22),
              level: AppLogLevel.error,
              name: 'n',
              message: message,
            ),
          ],
        ),
      );

      final clamped = snapshot.errorLogs.single['message']! as String;
      expect(clamped.length, 102399);
      final lastUnit = clamped.codeUnitAt(clamped.length - 1);
      expect(lastUnit >= 0xD800 && lastUnit <= 0xDBFF, isFalse);
    });
  });
}
