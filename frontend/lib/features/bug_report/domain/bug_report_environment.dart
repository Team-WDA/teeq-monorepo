/// 제보에 함께 보내는 앱·기기 환경 정보. [platform]은 `ANDROID` 또는 `IOS`다.
final class BugReportEnvironment {
  const BugReportEnvironment({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });

  final String appVersion;
  final String platform;
  final String osVersion;
  final String deviceModel;
}
