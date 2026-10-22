import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/bug_report/data/bug_report_repository_impl.dart';
import 'package:teeq/features/bug_report/data/image_picker_bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/presentation/bug_report_screen.dart';

import '../../../../support/fake_bug_report_image_picker.dart';
import '../../../../support/fake_bug_report_repository.dart';
import '../../../../support/my_page_harness.dart';

class _Harness {
  _Harness({FakeBugReportRepository? repository})
    : repository = repository ?? FakeBugReportRepository();

  final FakeBugReportRepository repository;
  final RecordingErrorHandler errorHandler = RecordingErrorHandler();
  final FakeBugReportImagePicker picker = FakeBugReportImagePicker(
    result: ['a.jpg'],
  );
  late final ProviderContainer container;

  Widget app() {
    container = ProviderContainer(
      overrides: [
        bugReportRepositoryProvider.overrideWithValue(repository),
        bugReportImagePickerProvider.overrideWithValue(picker),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/bug-report'),
              child: const Text('열기'),
            ),
          ),
        ),
        GoRoute(
          path: '/bug-report',
          builder: (context, state) => const BugReportScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }
}

Future<void> _open(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(harness.app());
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

bool _isSubmitEnabled(WidgetTester tester) =>
    tester
        .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
        .onPressed !=
    null;

void main() {
  testWidgets('submitButton_disabledWhenContentBlank', (tester) async {
    final harness = _Harness();
    await _open(tester, harness);

    expect(_isSubmitEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '   \n ');
    await tester.pump();
    expect(_isSubmitEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '버그');
    await tester.pump();
    expect(_isSubmitEnabled(tester), isTrue);
  });

  testWidgets('submitButton_disabledWhileSubmitting', (tester) async {
    final completer = Completer<String>();
    final harness = _Harness(
      repository: FakeBugReportRepository(completer: completer),
    );
    await _open(tester, harness);
    await tester.enterText(find.byType(TextField), '버그');
    await tester.pump();

    await tester.tap(find.text('제보하기'));
    await tester.pump();

    expect(_isSubmitEnabled(tester), isFalse);
    await tester.tap(find.text('제보하기'));
    await tester.pump();
    expect(harness.repository.submissions, hasLength(1));

    completer.complete('bug-report-1');
    await tester.pumpAndSettle();
    // 성공 토스트 타이머를 비운다.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('submit_success_showsToastAndPopsBack', (tester) async {
    final harness = _Harness();
    await _open(tester, harness);
    await tester.enterText(find.byType(TextField), '버그');
    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('제보하기'));
    await tester.pumpAndSettle();

    final submission = harness.repository.submissions.single;
    expect(submission.source, BugReportSource.user);
    expect(submission.content, '버그');
    expect(submission.imagePaths, ['a.jpg']);
    expect(submission.logSnapshot, isNull);
    expect(harness.container.read(toastControllerProvider), isNotNull);
    expect(find.text('열기'), findsOneWidget);
    expect(find.byType(BugReportScreen), findsNothing);
    // 토스트 타이머를 비운다.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('submit_failure_goesToErrorHandlerAndStaysOnScreen', (
    tester,
  ) async {
    final error = Exception('offline');
    final harness = _Harness(repository: FakeBugReportRepository(error: error));
    await _open(tester, harness);
    await tester.enterText(find.byType(TextField), '버그');
    await tester.pump();

    await tester.tap(find.text('제보하기'));
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, [error]);
    expect(find.byType(BugReportScreen), findsOneWidget);
    expect(_isSubmitEnabled(tester), isTrue);
  });
}
