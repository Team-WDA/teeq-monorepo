/// 프로필 사진이 업로드 전 검증을 통과하지 못한 이유.
enum ProfileImageIssue { unsupportedFormat, tooLarge }

/// 프로필 사진 사전 검증 규칙. 형식과 상한은 BE `MediaCategory`와 같다.
abstract final class ProfileImageRule {
  /// BE `media/core/constant/MediaCategory.java`의 `5L * 1024 * 1024`.
  static const int maxByteLength = 5 * 1024 * 1024;

  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

  /// 통과하면 null. 0바이트는 BE도 거절하므로 형식 오류로 둔다.
  static ProfileImageIssue? issueOf({
    required String fileName,
    required int byteLength,
  }) {
    if (byteLength <= 0 || !_hasAllowedExtension(fileName)) {
      return ProfileImageIssue.unsupportedFormat;
    }
    if (byteLength > maxByteLength) {
      return ProfileImageIssue.tooLarge;
    }
    return null;
  }

  static bool _hasAllowedExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) {
      return false;
    }
    return _allowedExtensions.contains(
      fileName.substring(dotIndex + 1).toLowerCase(),
    );
  }
}
