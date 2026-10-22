import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/bug_report/data/bug_report_environment_reader_impl.dart';

BugReportEnvironmentReaderImpl _reader({
  Future<String?> Function()? readAppVersion,
  String platform = 'ANDROID',
  Future<BugReportDeviceDescription> Function()? readDevice,
}) => BugReportEnvironmentReaderImpl(
  readAppVersion: readAppVersion ?? () async => '1.2.3',
  platform: platform,
  readDevice:
      readDevice ??
      () async => (osVersion: 'Android 15', deviceModel: 'Pixel 9'),
);

void main() {
  test('read_normalValues_passThroughUnchanged', () async {
    final environment = await _reader().read();

    expect(environment.appVersion, '1.2.3');
    expect(environment.platform, 'ANDROID');
    expect(environment.osVersion, 'Android 15');
    expect(environment.deviceModel, 'Pixel 9');
  });

  test('read_platformValueIsPassedThrough', () async {
    expect((await _reader(platform: 'IOS').read()).platform, 'IOS');
  });

  test('read_deviceReaderThrows_fallsBackToUnknown', () async {
    final environment = await _reader(
      readDevice: () async => throw StateError('plugin failure'),
    ).read();

    expect(environment.osVersion, 'unknown');
    expect(environment.deviceModel, 'unknown');
    expect(environment.appVersion, '1.2.3');
  });

  test('read_appVersionReaderThrows_fallsBackToUnknown', () async {
    final environment = await _reader(
      readAppVersion: () async => throw Exception('package info failure'),
    ).read();

    expect(environment.appVersion, 'unknown');
  });

  test('read_blankValues_fallBackToUnknown', () async {
    final environment = await _reader(
      readAppVersion: () async => '  ',
      readDevice: () async => (osVersion: null, deviceModel: ''),
    ).read();

    expect(environment.appVersion, 'unknown');
    expect(environment.osVersion, 'unknown');
    expect(environment.deviceModel, 'unknown');
  });

  test('read_overLongValues_areCutToServerLimits', () async {
    final environment = await _reader(
      readAppVersion: () async => 'v' * 80,
      readDevice: () async => (osVersion: 'o' * 150, deviceModel: 'm' * 150),
    ).read();

    expect(environment.appVersion, hasLength(50));
    expect(environment.osVersion, hasLength(100));
    expect(environment.deviceModel, hasLength(100));
  });

  test('read_cutDoesNotSplitSurrogatePair', () async {
    // 99자 뒤에 이모지(서로게이트 쌍)가 와서 100번째 단위가 쌍의 앞쪽이 된다.
    final model = '${'m' * 99}😀tail';

    final environment = await _reader(
      readDevice: () async => (osVersion: 'Android 15', deviceModel: model),
    ).read();

    expect(environment.deviceModel, 'm' * 99);
  });
}
