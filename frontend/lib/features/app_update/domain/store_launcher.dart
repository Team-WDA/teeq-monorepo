/// 스토어 주소를 외부 앱으로 여는 포트.
abstract interface class StoreLauncher {
  /// [storeUrl]을 열고 성공 여부를 돌려준다.
  Future<bool> open(String storeUrl);
}
