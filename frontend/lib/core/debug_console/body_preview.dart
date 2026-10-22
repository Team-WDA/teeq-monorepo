/// 요청·응답 본문 하나가 보관하는 최대 글자 수(약 100KB).
const int maxBodyPreviewLength = 100 * 1024;

/// 디버그 콘솔에 보여 줄 본문. 너무 길면 앞부분만 담고 잘렸음을 표시한다.
final class BodyPreview {
  const BodyPreview({
    required this.text,
    required this.isTruncated,
    required this.originalLength,
  });

  /// [fullText]가 [maxBodyPreviewLength]를 넘으면 앞부분만 남긴다.
  factory BodyPreview.fromText(String fullText) {
    final isTruncated = fullText.length > maxBodyPreviewLength;
    return BodyPreview(
      text: isTruncated
          ? fullText.substring(0, maxBodyPreviewLength)
          : fullText,
      isTruncated: isTruncated,
      originalLength: fullText.length,
    );
  }

  final String text;
  final bool isTruncated;

  /// 자르기 전 글자 수.
  final int originalLength;
}
