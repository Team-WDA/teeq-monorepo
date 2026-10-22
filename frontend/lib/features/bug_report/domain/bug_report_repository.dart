import 'package:teeq/features/bug_report/domain/bug_report_submission.dart';

/// 앱 제보 API.
abstract interface class BugReportRepository {
  /// 제보를 보내고 서버가 만든 `bugReportId`를 돌려준다.
  Future<String> submit(BugReportSubmission submission);
}
