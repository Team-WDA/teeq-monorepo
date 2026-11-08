/// 분석 이벤트 기록 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class AnalyticsGateway {
  Future<void> logScreenView(String screenName);

  Future<void> setUserId(String? userId);

  /// 모든 이벤트에 붙일 기본 파라미터. 플러그인이 문자열·숫자만 받으므로 숫자만 허용해 bool을 컴파일 때 막는다.
  Future<void> setDefaultEventParameters(Map<String, num> parameters);
}
