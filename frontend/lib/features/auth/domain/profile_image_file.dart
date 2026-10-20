import 'dart:typed_data';

/// 프로필 사진으로 올릴 파일. 파일명은 확장자로 형식을 가리는 데 쓰인다.
final class ProfileImageFile {
  const ProfileImageFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
