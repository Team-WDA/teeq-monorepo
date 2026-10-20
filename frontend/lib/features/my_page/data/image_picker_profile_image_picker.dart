import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/my_page/domain/profile_image_picker.dart';

part 'image_picker_profile_image_picker.g.dart';

/// `image_picker`로 시스템 사진 선택기(갤러리)만 연다. 카메라는 쓰지 않는다.
///
/// `requestFullMetadata`를 끄면 iOS가 사진 보관함 권한 요청 없이 PHPicker로 고른 사진만 넘겨준다.
/// iOS는 HEIC 등을 JPEG(`.jpg`)로 다시 인코딩해 넘기므로 BE가 받는 형식이 된다.
class ImagePickerProfileImagePicker implements ProfileImagePicker {
  ImagePickerProfileImagePicker(this._imagePicker);

  final ImagePicker _imagePicker;

  @override
  Future<ProfileImageFile?> pick() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
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
