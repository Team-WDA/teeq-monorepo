/// 앱 업데이트가 필요하다는 검사 결과. 업데이트가 필요 없으면 이 객체를 만들지 않는다.
class AppUpdateRequirement {
  const AppUpdateRequirement({
    required this.minimumVersion,
    required this.storeUrl,
  });

  /// 서버가 요구하는 최소 버전(`x.y.z`).
  final String minimumVersion;

  /// 업데이트하러 갈 스토어 주소.
  final String storeUrl;
}
