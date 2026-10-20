import 'dart:typed_data';

import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/my_page/domain/profile_image_picker.dart';

/// 정해 둔 파일(또는 취소를 뜻하는 null)을 돌려주는 사진 선택기. 호출 횟수를 센다.
class FakeProfileImagePicker implements ProfileImagePicker {
  FakeProfileImagePicker({this.result});

  /// 선택 결과. null이면 사용자가 취소한 것이다.
  final ProfileImageFile? result;

  int pickCount = 0;

  /// 바이트 수가 [byteLength]인 사진 파일.
  static ProfileImageFile imageOf({
    String fileName = 'photo.jpg',
    int byteLength = 1024,
  }) => ProfileImageFile(fileName: fileName, bytes: Uint8List(byteLength));

  @override
  Future<ProfileImageFile?> pick() async {
    pickCount++;
    return result;
  }
}
