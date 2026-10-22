import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/bug_report/domain/bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/domain/bug_report_input_limits.dart';

part 'image_picker_bug_report_image_picker.g.dart';

/// `image_picker`로 시스템 사진 선택기(갤러리)만 연다. 카메라는 쓰지 않는다.
///
/// `requestFullMetadata`를 끄면 iOS가 사진 보관함 권한 요청 없이 고른 사진만 넘겨준다.
/// `limit`이 1이면 플러그인이 단일 선택으로 처리하므로 [limit] 그대로 넘겨도 된다.
class ImagePickerBugReportImagePicker implements BugReportImagePicker {
  ImagePickerBugReportImagePicker(this._imagePicker);

  final ImagePicker _imagePicker;

  @override
  Future<List<String>> pick({required int limit}) async {
    final files = await _imagePicker.pickMultiImage(
      maxWidth: BugReportInputLimits.imageMaxDimension,
      maxHeight: BugReportInputLimits.imageMaxDimension,
      imageQuality: BugReportInputLimits.imageQuality,
      limit: limit,
      requestFullMetadata: false,
    );
    return [for (final file in files) file.path];
  }
}

@Riverpod(keepAlive: true)
BugReportImagePicker bugReportImagePicker(Ref ref) =>
    ImagePickerBugReportImagePicker(ImagePicker());
