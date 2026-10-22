import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/bug_report/data/bug_report_repository_impl.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/presentation/bug_report_submission_controller.dart';

import '../../../../support/fake_bug_report_repository.dart';
import '../../../../support/my_page_harness.dart';

ProviderContainer _container(
  FakeBugReportRepository repository,
  RecordingErrorHandler errorHandler,
) {
  final container = ProviderContainer(
    overrides: [
      bugReportRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  // 자동 해제되는 provider가 테스트 중 사라지지 않게 구독을 유지한다.
  container.listen(bugReportSubmissionControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('submit sends the submission and returns true', () async {
    final repository = FakeBugReportRepository();
    final container = _container(repository, RecordingErrorHandler());

    final result = await container
        .read(bugReportSubmissionControllerProvider.notifier)
        .submit(
          source: BugReportSource.user,
          content: '앱이 멈춰요',
          imagePaths: const ['a.jpg'],
        );

    expect(result, isTrue);
    expect(repository.submissions, hasLength(1));
    expect(repository.submissions.single.source, BugReportSource.user);
    expect(repository.submissions.single.content, '앱이 멈춰요');
    expect(repository.submissions.single.imagePaths, ['a.jpg']);
    expect(repository.submissions.single.logSnapshot, isNull);
  });

  test(
    'submit routes failures to the error handler and returns false',
    () async {
      final error = Exception('offline');
      final errorHandler = RecordingErrorHandler();
      final container = _container(
        FakeBugReportRepository(error: error),
        errorHandler,
      );

      final result = await container
          .read(bugReportSubmissionControllerProvider.notifier)
          .submit(
            source: BugReportSource.user,
            content: 'x',
            imagePaths: const [],
          );

      expect(result, isFalse);
      expect(errorHandler.handledErrors, [error]);
      expect(
        container.read(bugReportSubmissionControllerProvider).isLoading,
        isFalse,
      );
    },
  );

  test('submit ignores re-entry while a request is in progress', () async {
    final completer = Completer<String>();
    final repository = FakeBugReportRepository(completer: completer);
    final container = _container(repository, RecordingErrorHandler());
    final notifier = container.read(
      bugReportSubmissionControllerProvider.notifier,
    );

    final first = notifier.submit(
      source: BugReportSource.user,
      content: 'x',
      imagePaths: const [],
    );
    final second = await notifier.submit(
      source: BugReportSource.user,
      content: 'x',
      imagePaths: const [],
    );
    completer.complete('bug-report-1');

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repository.submissions, hasLength(1));
  });
}
