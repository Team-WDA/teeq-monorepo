import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/debug_console/bug_report_log_snapshot_builder.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/bug_report/data/bug_report_repository_impl.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/domain/bug_report_submission.dart';

part 'bug_report_submission_controller.g.dart';

/// 제보 제출 진행 상태를 보관한다. 로딩 중이면 제출 중이다.
@riverpod
class BugReportSubmissionController extends _$BugReportSubmissionController {
  @override
  FutureOr<void> build() {}

  /// 제보를 보내고 성공 여부를 돌려준다. 이미 제출 중이면 보내지 않고 false를 돌려준다.
  /// 실패는 중앙 [ErrorHandler]가 표시한다.
  Future<bool> submit({
    required BugReportSource source,
    required String content,
    required List<String> imagePaths,
    BugReportLogSnapshot? logSnapshot,
  }) async {
    if (state.isLoading) {
      return false;
    }
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final repository = ref.read(bugReportRepositoryProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    state = const AsyncLoading();
    try {
      await repository.submit(
        BugReportSubmission(
          source: source,
          content: content,
          imagePaths: imagePaths,
          logSnapshot: logSnapshot,
        ),
      );
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } on Object catch (error) {
      errorHandler.handle(error);
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return false;
    }
  }
}
