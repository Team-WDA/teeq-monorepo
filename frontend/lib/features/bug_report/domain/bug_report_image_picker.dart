/// 갤러리에서 제보에 붙일 이미지를 고르는 포트. 화면과 테스트가 선택기 플러그인을 직접 알지 않게 한다.
abstract interface class BugReportImagePicker {
  /// 최대 [limit]장을 골라 파일 경로로 돌려준다. 사용자가 취소하면 빈 목록이다.
  /// 선택기 오류는 그대로 던진다.
  Future<List<String>> pick({required int limit});
}
