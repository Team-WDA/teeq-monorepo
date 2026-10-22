import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/body_preview.dart';
import 'package:teeq/core/debug_console/curl_command_builder.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';

NetworkLogEntry _entry({
  String method = 'GET',
  Map<String, String> requestHeaders = const {},
  BodyPreview? requestBody,
}) => NetworkLogEntry(
  id: '1',
  startedAt: DateTime.utc(2026, 10, 22),
  method: method,
  url: 'https://api.example.test/a',
  requestHeaders: requestHeaders,
  requestBody: requestBody,
);

void main() {
  test('builds a one-line command with headers', () {
    final command = CurlCommandBuilder.build(
      _entry(requestHeaders: const {'Accept': 'application/json'}),
    );

    expect(
      command,
      "curl -X GET 'https://api.example.test/a' -H 'Accept: application/json'",
    );
  });

  test('omits --data-raw when there is no request body', () {
    final command = CurlCommandBuilder.build(_entry(method: 'DELETE'));

    expect(command, isNot(contains('--data-raw')));
  });

  test('escapes single quotes in the body', () {
    final command = CurlCommandBuilder.build(
      _entry(
        method: 'POST',
        requestBody: BodyPreview.fromText('{"a":"it\'s"}'),
      ),
    );

    expect(command, contains("--data-raw '{\"a\":\"it'\\''s\"}'"));
  });

  test('appends a comment line when the body was truncated', () {
    final command = CurlCommandBuilder.build(
      _entry(
        method: 'POST',
        requestBody: BodyPreview.fromText('a' * (maxBodyPreviewLength + 5)),
      ),
    );

    expect(
      command.split('\n').last,
      '# 본문이 잘려 일부만 포함됨 (전체 ${maxBodyPreviewLength + 5}글자)',
    );
  });
}
