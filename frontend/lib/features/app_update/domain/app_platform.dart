/// 최소버전을 검사하는 앱 플랫폼. 서버가 지원하는 값만 둔다.
enum AppPlatform {
  android('ANDROID'),
  ios('IOS');

  const AppPlatform(this.serverName);

  /// 서버 API가 쓰는 `UPPER_SNAKE_CASE` 값.
  final String serverName;
}
