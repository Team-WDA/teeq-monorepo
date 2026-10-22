/// 앱 로그의 심각도.
///
/// [developerLogValue]는 `dart:developer`의 `log`가 받는 level 값과 맞춘다
/// (FINE 500, INFO 800, WARNING 900, SEVERE 1000).
enum AppLogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const AppLogLevel(this.developerLogValue);

  final int developerLogValue;
}
