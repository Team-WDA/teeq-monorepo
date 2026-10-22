import 'dart:async';

import 'package:teeq/features/bug_report/domain/bug_report_repository.dart';
import 'package:teeq/features/bug_report/domain/bug_report_submission.dart';

/// 받은 제출 내용을 기록하는 제보 저장소. [completer]를 주면 그것이 끝날 때까지 응답하지 않는다.
class FakeBugReportRepository implements BugReportRepository {
  FakeBugReportRepository({this.error, this.completer});

  final Object? error;
  final Completer<String>? completer;

  final List<BugReportSubmission> submissions = [];

  @override
  Future<String> submit(BugReportSubmission submission) async {
    submissions.add(submission);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    final pending = completer;
    if (pending != null) {
      return pending.future;
    }
    return 'bug-report-1';
  }
}
