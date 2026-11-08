/// 분석 이벤트 기록 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class AnalyticsGateway {
  Future<void> logScreenView(String screenName);

  Future<void> setUserId(String? userId);

  Future<void> setDefaultEventParameters(Map<String, Object> parameters);
}
