import 'package:teeq/core/debug_console/bug_report_log_snapshot_builder.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';

/// 제보 제출 내용. [logSnapshot]은 개발자 콘솔 출처일 때만 채운다.
final class BugReportSubmission {
  const BugReportSubmission({
    required this.source,
    required this.content,
    required this.imagePaths,
    this.logSnapshot,
  });

  final BugReportSource source;
  final String content;

  /// 첨부할 이미지 파일 경로(최대 5장).
  final List<String> imagePaths;
  final BugReportLogSnapshot? logSnapshot;
}
