import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/debug_console/bug_report_log_snapshot_builder.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/bug_report/data/bug_report_environment_reader_impl.dart';
import 'package:teeq/features/bug_report/data/bug_report_repository_impl.dart';
import 'package:teeq/features/bug_report/domain/bug_report_environment.dart';
import 'package:teeq/features/bug_report/domain/bug_report_environment_reader.dart';
import 'package:teeq/features/bug_report/domain/bug_report_repository.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/domain/bug_report_submission.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _path = '/api/bug-reports';

const _environment = BugReportEnvironment(
  appVersion: '1.2.3',
  platform: 'ANDROID',
  osVersion: 'Android 15',
  deviceModel: 'Pixel 9',
);

final class _FakeEnvironmentReader implements BugReportEnvironmentReader {
  @override
  Future<BugReportEnvironment> read() async => _environment;
}

({BugReportRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(apiBaseUrl: 'https://api.example.test'),
      ),
      bugReportEnvironmentReaderProvider.overrideWithValue(
        _FakeEnvironmentReader(),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  adapter.on(_path, [
    ScriptedReply.json(201, {'bugReportId': 'bug-report-1'}),
  ]);
  return (
    repository: container.read(bugReportRepositoryProvider),
    adapter: adapter,
  );
}

FormData _formOf(ScriptedHttpClientAdapter adapter) =>
    adapter.requestsTo(_path).single.data as FormData;

MultipartFile _requestPartOf(FormData form) =>
    form.files.singleWhere((entry) => entry.key == 'request').value;

Future<Map<String, dynamic>> _readRequestBody(FormData form) async {
  final part = _requestPartOf(form).clone();
  final bytes = await part.finalize().expand((chunk) => chunk).toList();
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

void main() {
  test('submit_buildsMultipartWithJsonRequestPart', () async {
    final (:repository, :adapter) = _setUp();

    final bugReportId = await repository.submit(
      const BugReportSubmission(
        source: BugReportSource.user,
        content: '통화 화면에서 앱이 멈춰요',
        imagePaths: [],
      ),
    );

    expect(bugReportId, 'bug-report-1');
    final form = _formOf(adapter);
    expect(
      _requestPartOf(form).contentType.toString(),
      startsWith('application/json'),
    );
    expect(_requestPartOf(form).filename, 'request.json');
    expect(await _readRequestBody(form), {
      'source': 'USER',
      'content': '통화 화면에서 앱이 멈춰요',
      'environment': {
        'appVersion': '1.2.3',
        'platform': 'ANDROID',
        'osVersion': 'Android 15',
        'deviceModel': 'Pixel 9',
      },
    });
  });

  test('submit_userSource_omitsLogFields', () async {
    final (:repository, :adapter) = _setUp();

    await repository.submit(
      const BugReportSubmission(
        source: BugReportSource.user,
        content: '내용',
        imagePaths: [],
      ),
    );

    final body = await _readRequestBody(_formOf(adapter));
    expect(body.containsKey('errorLogs'), isFalse);
    expect(body.containsKey('networkLogs'), isFalse);
    expect(body.containsKey('omittedErrorLogCount'), isFalse);
    expect(body.containsKey('omittedNetworkLogCount'), isFalse);
  });

  test('submit_developerConsole_includesLogsAndOmittedCounts', () async {
    final (:repository, :adapter) = _setUp();
    final errorLog = {'level': 'SEVERE', 'name': 'x', 'message': 'm'};
    final networkLog = {'method': 'GET', 'url': 'https://a.test'};

    await repository.submit(
      BugReportSubmission(
        source: BugReportSource.developerConsole,
        content: '내용',
        imagePaths: const [],
        logSnapshot: BugReportLogSnapshot(
          errorLogs: [errorLog],
          networkLogs: [networkLog],
          omittedErrorLogCount: 3,
          omittedNetworkLogCount: 4,
        ),
      ),
    );

    final body = await _readRequestBody(_formOf(adapter));
    expect(body['source'], 'DEVELOPER_CONSOLE');
    expect(body['errorLogs'], [errorLog]);
    expect(body['networkLogs'], [networkLog]);
    expect(body['omittedErrorLogCount'], 3);
    expect(body['omittedNetworkLogCount'], 4);
  });

  test('submit_attachesEveryImage', () async {
    final (:repository, :adapter) = _setUp();
    final directory = Directory.systemTemp.createTempSync('bug_report_test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final paths = [
      for (final name in ['a.png', 'b.png', 'c.png'])
        (File('${directory.path}/$name')..writeAsBytesSync([1, 2, 3])).path,
    ];

    await repository.submit(
      BugReportSubmission(
        source: BugReportSource.user,
        content: '내용',
        imagePaths: paths,
      ),
    );

    final imageEntries = _formOf(adapter).files
        .where((entry) => entry.key == 'images')
        .toList();
    expect(imageEntries, hasLength(3));
    expect(
      imageEntries.map((entry) => entry.value),
      everyElement(isA<MultipartFile>()),
    );
    expect(imageEntries.map((entry) => entry.value.filename), [
      'a.png',
      'b.png',
      'c.png',
    ]);
  });

  test('environmentReader_combinesVersionPlatformAndDevice', () async {
    final reader = BugReportEnvironmentReaderImpl(
      readAppVersion: () async => '1.2.3',
      platform: 'IOS',
      readDevice: () async =>
          (osVersion: 'iOS 18.1', deviceModel: 'iPhone16,1'),
    );

    final environment = await reader.read();

    expect(environment.appVersion, '1.2.3');
    expect(environment.platform, 'IOS');
    expect(environment.osVersion, 'iOS 18.1');
    expect(environment.deviceModel, 'iPhone16,1');
  });
}
