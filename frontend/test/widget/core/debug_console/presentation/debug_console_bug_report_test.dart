import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/bug_report/data/bug_report_repository_impl.dart';
import 'package:teeq/features/bug_report/data/image_picker_bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_content_field.dart';

import '../../../../support/fake_auth_status_controller.dart';
import '../../../../support/fake_bug_report_image_picker.dart';
import '../../../../support/fake_bug_report_repository.dart';
import '../../../../support/my_page_harness.dart';

class _FakeDebugConsoleStore extends DebugConsoleStore {
  _FakeDebugConsoleStore(this._initialState);

  final DebugConsoleState _initialState;

  @override
  DebugConsoleState build() => _initialState;
}

class _Harness {
  _Harness({required this.authStatus, FakeBugReportRepository? repository})
    : repository = repository ?? FakeBugReportRepository();

  final AuthStatus authStatus;
  final FakeBugReportRepository repository;
  final RecordingErrorHandler errorHandler = RecordingErrorHandler();
  late final ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [
        authStatusControllerProvider.overrideWith(
          () => FakeAuthStatusController(authStatus),
        ),
        debugConsoleStoreProvider.overrideWith(
          () => _FakeDebugConsoleStore(
            DebugConsoleState(
              errorLogs: [
                AppLogEntry(
                  timestamp: DateTime.utc(2026, 10, 22),
                  level: AppLogLevel.error,
                  name: 'Logger',
                  message: 'boom',
                ),
              ],
            ),
          ),
        ),
        bugReportRepositoryProvider.overrideWithValue(repository),
        bugReportImagePickerProvider.overrideWithValue(
          FakeBugReportImagePicker(),
        ),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DebugConsolePanel(),
        ),
      ),
    );
  }
}

Finder _contentField() => find.descendant(
  of: find.byType(BugReportContentField),
  matching: find.byType(TextField),
);

Finder _reportButton() => find.byTooltip('제보');

Finder _submitButton() => find.text('제보하기');

void main() {
  testWidgets('reportButton_disabledWhenLoggedOut', (tester) async {
    final harness = _Harness(authStatus: AuthStatus.signedOut);
    await harness.pump(tester);

    await tester.tap(_reportButton());
    await tester.pump();

    expect(_contentField(), findsNothing);
    expect(harness.container.read(toastControllerProvider), '로그인 후 제보할 수 있어요');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('reportButton_opensSheetWhenLoggedIn', (tester) async {
    final harness = _Harness(authStatus: AuthStatus.signedIn);
    await harness.pump(tester);

    await tester.tap(_reportButton());
    await tester.pump();

    expect(_contentField(), findsOneWidget);
    expect(harness.container.read(toastControllerProvider), isNull);
  });

  testWidgets('sheet_blocksBlankContent', (tester) async {
    final harness = _Harness(authStatus: AuthStatus.signedIn);
    await harness.pump(tester);
    await tester.tap(_reportButton());
    await tester.pump();

    await tester.enterText(_contentField(), '   ');
    await tester.pump();
    await tester.tap(_submitButton());
    await tester.pump();

    expect(harness.repository.submissions, isEmpty);
  });

  testWidgets('sheet_submitsDeveloperConsoleSourceWithSnapshot', (
    tester,
  ) async {
    final harness = _Harness(authStatus: AuthStatus.signedIn);
    await harness.pump(tester);
    await tester.tap(_reportButton());
    await tester.pump();

    await tester.enterText(_contentField(), '통화가 끊겨요');
    await tester.pump();
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    final submission = harness.repository.submissions.single;
    expect(submission.source, BugReportSource.developerConsole);
    expect(submission.content, '통화가 끊겨요');
    expect(submission.logSnapshot?.errorLogs, hasLength(1));
    expect(_contentField(), findsNothing);
    expect(harness.container.read(toastControllerProvider), '제보가 접수되었어요');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('sheet_staysOpenWithInputWhenSubmitFails', (tester) async {
    final harness = _Harness(
      authStatus: AuthStatus.signedIn,
      repository: FakeBugReportRepository(error: Exception('fail')),
    );
    await harness.pump(tester);
    await tester.tap(_reportButton());
    await tester.pump();

    await tester.enterText(_contentField(), '통화가 끊겨요');
    await tester.pump();
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(find.text('통화가 끊겨요'), findsOneWidget);
  });
}
