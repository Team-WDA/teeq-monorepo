import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/my_page/domain/profile_image_picker.dart';

part 'image_picker_profile_image_picker.g.dart';

/// `image_picker`로 시스템 사진 선택기(갤러리)만 연다. 카메라는 쓰지 않는다.
///
/// `requestFullMetadata`를 끄면 iOS가 사진 보관함 권한 요청 없이 PHPicker로 고른 사진만 넘겨준다.
/// iOS는 HEIC 등을 JPEG(`.jpg`)로 다시 인코딩해 넘기므로 BE가 받는 형식이 된다.
///
/// 프로필 사진은 작은 원으로 보여 주므로 원본 해상도가 필요 없다. 고해상도 휴대폰 사진이
/// 5MB 상한에 걸리지 않도록 선택기가 줄이고 다시 압축하게 한다(자르기가 아니라 축소다).
class ImagePickerProfileImagePicker implements ProfileImagePicker {
  ImagePickerProfileImagePicker(this._imagePicker);

  static const double _maxDimension = 1080;
  static const int _imageQuality = 85;

  final ImagePicker _imagePicker;

  @override
  Future<ProfileImageFile?> pick() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
    if (file == null) {
      return null;
    }
    return ProfileImageFile(
      fileName: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}

@Riverpod(keepAlive: true)
ProfileImagePicker profileImagePicker(Ref ref) =>
    ImagePickerProfileImagePicker(ImagePicker());
