import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/features/bug_report/domain/bug_report_environment.dart';
import 'package:teeq/features/bug_report/domain/bug_report_environment_reader.dart';

part 'bug_report_environment_reader_impl.g.dart';

/// 읽지 못했거나 비어 있을 때 서버에 보내는 자리 표시 값.
const String bugReportUnknownEnvironmentValue = 'unknown';

const int _appVersionMaxLength = 50;
const int _deviceFieldMaxLength = 100;

/// 플랫폼에서 읽은 OS 버전과 기기 모델 원본. 읽지 못한 값은 null이다.
typedef BugReportDeviceDescription = ({String? osVersion, String? deviceModel});

/// 앱 버전, 플랫폼, 기기 정보를 모아 환경 정보를 만드는 구현.
/// 읽기에 실패하거나 값이 비면 [bugReportUnknownEnvironmentValue]로 대체하고,
/// 서버 길이 제한(앱 버전 50자, OS 버전·기기 모델 100자)에 맞춰 자른다.
/// 제보 전송이 환경 정보 때문에 막히지 않도록 [read]는 예외를 던지지 않는다.
final class BugReportEnvironmentReaderImpl
    implements BugReportEnvironmentReader {
  BugReportEnvironmentReaderImpl({
    required this._readAppVersion,
    required this._platform,
    required this._readDevice,
  });

  final Future<String?> Function() _readAppVersion;
  final String _platform;
  final Future<BugReportDeviceDescription> Function() _readDevice;

  @override
  Future<BugReportEnvironment> read() async {
    final appVersion = await _safely(_readAppVersion);
    final device = await _safely(_readDevice);
    return BugReportEnvironment(
      appVersion: _normalize(appVersion, _appVersionMaxLength),
      platform: _platform,
      osVersion: _normalize(device?.osVersion, _deviceFieldMaxLength),
      deviceModel: _normalize(device?.deviceModel, _deviceFieldMaxLength),
    );
  }

  // 플러그인이 던지는 모든 실패(Exception뿐 아니라 매핑 중 TypeError 포함)를 대체값으로 흡수한다.
  Future<T?> _safely<T>(Future<T> Function() reader) async {
    try {
      return await reader();
    } on Object {
      return null;
    }
  }

  String _normalize(String? value, int maxLength) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return bugReportUnknownEnvironmentValue;
    }
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    // UTF-16 단위로 자르되 서로게이트 쌍의 앞쪽만 남기지 않는다.
    final endsInsidePair = _isHighSurrogate(trimmed.codeUnitAt(maxLength - 1));
    return trimmed.substring(0, endsInsidePair ? maxLength - 1 : maxLength);
  }

  bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}

String? _nonBlankOrNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;

Future<BugReportDeviceDescription> _readDeviceDescription() async {
  final plugin = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    final release = _nonBlankOrNull(info.version.release);
    return (
      osVersion: release == null ? null : 'Android $release',
      deviceModel: _nonBlankOrNull(info.model),
    );
  }
  final info = await plugin.iosInfo;
  final systemVersion = _nonBlankOrNull(info.systemVersion);
  return (
    osVersion: systemVersion == null ? null : 'iOS $systemVersion',
    deviceModel: _nonBlankOrNull(info.utsname.machine),
  );
}

@Riverpod(keepAlive: true)
BugReportEnvironmentReader bugReportEnvironmentReader(Ref ref) =>
    BugReportEnvironmentReaderImpl(
      readAppVersion: () => ref.read(appVersionProvider.future),
      platform: Platform.isAndroid ? 'ANDROID' : 'IOS',
      readDevice: _readDeviceDescription,
    );
