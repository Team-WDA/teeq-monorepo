import 'package:teeq/features/auth/domain/profile_image_file.dart';

/// 갤러리에서 프로필 사진 한 장을 고르는 포트. 화면과 테스트가 선택기 플러그인을 직접 알지 않게 한다.
abstract interface class ProfileImagePicker {
  /// 사용자가 선택을 취소하면 null이다. 선택기 오류는 그대로 던진다.
  Future<ProfileImageFile?> pick();
}
