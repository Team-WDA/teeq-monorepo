/// 피드백 입력 글자 수 상한. BE `DetailedFeedbackRequest`의 `@Size`와 같다.
/// BE는 UTF-16 코드 유닛 수로 세므로 클라이언트도 같은 기준으로 자른다.
abstract final class FeedbackInputLimits {
  static const int reasonMaxLength = 100;
  static const int freeTextMaxLength = 1000;
  static const int startReasonOtherTextMaxLength = 100;

  /// [text]를 UTF-16 코드 유닛 [maxLength]개까지만 남긴다.
  /// 서로게이트 쌍이 경계에 걸리면 깨진 반쪽을 남기지 않고 쌍 전체를 버린다.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    final isSplittingSurrogatePair =
        _isHighSurrogate(text.codeUnitAt(maxLength - 1)) &&
        _isLowSurrogate(text.codeUnitAt(maxLength));
    return text.substring(
      0,
      isSplittingSurrogatePair ? maxLength - 1 : maxLength,
    );
  }

  static const int _highSurrogateStart = 0xD800;
  static const int _highSurrogateEnd = 0xDBFF;
  static const int _lowSurrogateStart = 0xDC00;
  static const int _lowSurrogateEnd = 0xDFFF;

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= _highSurrogateStart && codeUnit <= _highSurrogateEnd;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= _lowSurrogateStart && codeUnit <= _lowSurrogateEnd;
}
