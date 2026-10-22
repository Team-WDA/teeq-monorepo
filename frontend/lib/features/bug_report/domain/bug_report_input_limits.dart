/// 제보 입력 한도. BE `BugReportCreateRequest`의 `@Size`와 이미지 개수 상한을 따른다.
abstract final class BugReportInputLimits {
  /// BE는 자바 `char`(UTF-16 코드 유닛)로 세므로 Dart `String.length`와 같은 기준이다.
  static const int contentMaxLength = 2000;
  static const int imageMaxCount = 5;

  /// 선택기가 이미지를 줄일 때의 긴 변 상한(px)과 압축 품질.
  static const double imageMaxDimension = 1920;
  static const int imageQuality = 85;

  /// [existing] 뒤에 [picked]를 붙이되 이미 붙은 경로는 건너뛰고 [imageMaxCount]장을 넘기지 않는다.
  static List<String> mergeImagePaths(
    List<String> existing,
    List<String> picked,
  ) {
    final merged = [...existing];
    for (final path in picked) {
      if (merged.length >= imageMaxCount) {
        break;
      }
      if (!merged.contains(path)) {
        merged.add(path);
      }
    }
    return List.unmodifiable(merged);
  }
}
