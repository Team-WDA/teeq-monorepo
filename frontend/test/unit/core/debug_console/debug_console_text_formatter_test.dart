import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/body_preview.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

NetworkLogEntry _entry({String id = '1', BodyPreview? responseBody}) =>
    NetworkLogEntry(
      id: id,
      startedAt: DateTime.utc(2026, 10, 22, 10),
      method: 'GET',
      url: 'https://api.example.test/a$id',
      requestHeaders: const {'Authorization': 'Bearer x'},
      requestBody: BodyPreview.fromText('request-body'),
      statusCode: 200,
      responseHeaders: const {'content-type': 'application/json'},
      responseBody: responseBody ?? BodyPreview.fromText('response-body'),
      duration: const Duration(milliseconds: 120),
    );

AppLogEntry _log({String? errorDescription, String? stackTraceText}) =>
    AppLogEntry(
      timestamp: DateTime.utc(2026, 10, 22, 10),
      level: AppLogLevel.warning,
      name: 'ErrorHandler',
      message: '메시지',
      errorDescription: errorDescription,
      stackTraceText: stackTraceText,
    );

void main() {
  group('networkEntry', () {
    test('includes request line, headers, bodies and timing', () {
      final text = DebugConsoleTextFormatter.networkEntry(_entry());

      expect(text, contains('GET https://api.example.test/a1'));
      expect(text, contains('200'));
      expect(text, contains('120ms'));
      expect(text, contains('Authorization: Bearer x'));
      expect(text, contains('request-body'));
      expect(text, contains('content-type: application/json'));
      expect(text, contains('response-body'));
    });

    test('marks truncated bodies with the original length', () {
      final text = DebugConsoleTextFormatter.networkEntry(
        _entry(
          responseBody: BodyPreview.fromText('a' * (maxBodyPreviewLength + 1)),
        ),
      );

      expect(text, contains('…(잘림, 전체 ${maxBodyPreviewLength + 1}글자)'));
    });
  });

  test('networkEntries separates entries with a blank line', () {
    final text = DebugConsoleTextFormatter.networkEntries([
      _entry(id: '1'),
      _entry(id: '2'),
    ]);

    expect(text, contains('\n\n'));
    expect(text.indexOf('/a1'), lessThan(text.indexOf('/a2')));
  });

  group('applicationLog', () {
    test('formats a single line with time, level, name and message', () {
      final text = DebugConsoleTextFormatter.applicationLog(_log());

      expect(text, '[2026-10-22T10:00:00.000Z] [WARNING] ErrorHandler: 메시지');
    });

    test('adds error and stack trace lines when present', () {
      final text = DebugConsoleTextFormatter.applicationLog(
        _log(errorDescription: 'boom', stackTraceText: '#0 main'),
      );

      expect(text, contains('오류: boom'));
      expect(text, contains('스택:\n#0 main'));
    });
  });

  test('applicationLogs joins entries with a blank line', () {
    final text = DebugConsoleTextFormatter.applicationLogs([_log(), _log()]);

    expect(text.split('\n\n'), hasLength(2));
  });

  group('bodyText and headersText', () {
    test(
      'bodyText appends the truncation notice only for truncated bodies',
      () {
        expect(
          DebugConsoleTextFormatter.bodyText(BodyPreview.fromText('짧은 본문')),
          '짧은 본문',
        );
        expect(
          DebugConsoleTextFormatter.bodyText(
            BodyPreview.fromText('a' * (maxBodyPreviewLength + 3)),
          ),
          endsWith('…(잘림, 전체 ${maxBodyPreviewLength + 3}글자)'),
        );
      },
    );

    test('headersText lists one header per line or a placeholder', () {
      expect(
        DebugConsoleTextFormatter.headersText(const {'a': '1', 'b': '2'}),
        'a: 1\nb: 2',
      );
      expect(DebugConsoleTextFormatter.headersText(const {}), '(없음)');
    });
  });

  group('applicationInformation', () {
    test('lists version, server, operating system and route', () {
      final text = DebugConsoleTextFormatter.applicationInformation(
        appVersion: '1.2.3',
        apiBaseUrl: 'https://api.example.test',
        operatingSystem: 'ios 17',
        route: '/my',
      );

      expect(text, contains('앱 버전: 1.2.3'));
      expect(text, contains('API 서버: https://api.example.test'));
      expect(text, contains('운영체제: ios 17'));
      expect(text, contains('현재 라우트: /my'));
    });

    test('shows a placeholder when the version is unknown', () {
      final text = DebugConsoleTextFormatter.applicationInformation(
        appVersion: null,
        apiBaseUrl: 'https://api.example.test',
        operatingSystem: 'ios 17',
        route: '/my',
      );

      expect(text, contains('앱 버전: 알 수 없음'));
    });
  });
}
