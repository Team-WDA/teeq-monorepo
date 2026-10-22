import 'package:teeq/features/bug_report/domain/bug_report_image_picker.dart';

/// 정해 둔 경로를 돌려주는 이미지 선택기. 요청받은 한도와 호출 횟수를 기록한다.
class FakeBugReportImagePicker implements BugReportImagePicker {
  FakeBugReportImagePicker({this.result = const []});

  final List<String> result;

  int pickCount = 0;
  int? lastLimit;

  @override
  Future<List<String>> pick({required int limit}) async {
    pickCount++;
    lastLimit = limit;
    return result;
  }
}
