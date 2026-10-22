import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/app_update/data/url_store_launcher.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/app_update/presentation/update_required_screen.dart';

import '../support/fake_app_update_controller.dart';
import '../support/fake_store_launcher.dart';
import '../support/my_page_harness.dart';

const _storeUrl = 'https://store.example.test/teeq';
const _requirement = AppUpdateRequirement(
  minimumVersion: '1.3.0',
  storeUrl: _storeUrl,
);

Future<RecordingErrorHandler> _pumpScreen(
  WidgetTester tester, {
  required FakeStoreLauncher launcher,
  AppUpdateRequirement? requirement = _requirement,
}) async {
  final errorHandler = RecordingErrorHandler();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUpdateControllerProvider.overrideWith(
          () => FakeAppUpdateController(initialRequirement: requirement),
        ),
        storeLauncherProvider.overrideWithValue(launcher),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const UpdateRequiredScreen(),
      ),
    ),
  );
  return errorHandler;
}

void main() {
  testWidgets('제목, 설명, 업데이트하기 버튼을 보여 준다', (tester) async {
    await _pumpScreen(tester, launcher: FakeStoreLauncher());

    expect(find.text('업데이트가 필요해요'), findsOneWidget);
    expect(
      find.text('더 안전하고 편하게 TeeQ를 쓰려면 최신 버전으로 업데이트해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('업데이트하기'), findsOneWidget);
  });

  testWidgets('버튼을 탭하면 상태의 스토어 주소로 열기를 한 번 요청한다', (tester) async {
    final launcher = FakeStoreLauncher();
    await _pumpScreen(tester, launcher: launcher);

    await tester.tap(find.text('업데이트하기'));
    await tester.pump();

    expect(launcher.openedUrls, [_storeUrl]);
  });

  testWidgets('요구사항 상태가 없으면 버튼이 비활성이고 열기를 요청하지 않는다', (tester) async {
    final launcher = FakeStoreLauncher();
    await _pumpScreen(tester, launcher: launcher, requirement: null);

    await tester.tap(find.text('업데이트하기'));
    await tester.pump();

    expect(launcher.openedUrls, isEmpty);
    final button = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(UpdateRequiredScreen),
        matching: find.bySemanticsLabel('업데이트하기'),
      ),
    );
    expect(button.properties.enabled, isFalse);
  });

  testWidgets('열기가 끝나기 전에 연타해도 열기 요청은 한 번이고 끝나면 다시 탭할 수 있다', (tester) async {
    final gate = Completer<void>();
    final launcher = FakeStoreLauncher(gate: gate);
    await _pumpScreen(tester, launcher: launcher);

    await tester.tap(find.text('업데이트하기'));
    await tester.pump();
    await tester.tap(find.text('업데이트하기'));
    await tester.pump();
    expect(launcher.openedUrls, hasLength(1));

    gate.complete();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('업데이트하기'));
    await tester.pump();

    expect(launcher.openedUrls, hasLength(2));
  });

  testWidgets('열기가 false를 돌려주면 ErrorHandler로 보낸다', (tester) async {
    final errorHandler = await _pumpScreen(
      tester,
      launcher: FakeStoreLauncher(result: false),
    );

    await tester.tap(find.text('업데이트하기'));
    await tester.pump();
    await tester.pump();

    expect(errorHandler.handledErrors, hasLength(1));
    expect(errorHandler.handledErrors.single, isA<UnexpectedException>());
  });

  testWidgets('열기가 예외를 던지면 ErrorHandler로 보낸다', (tester) async {
    final failure = StateError('launch failed');
    final errorHandler = await _pumpScreen(
      tester,
      launcher: FakeStoreLauncher(error: failure),
    );

    await tester.tap(find.text('업데이트하기'));
    await tester.pump();
    await tester.pump();

    expect(errorHandler.handledErrors, [failure]);
  });

  testWidgets('시스템 뒤로 가기로 화면이 닫히지 않는다', (tester) async {
    await _pumpScreen(tester, launcher: FakeStoreLauncher());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    // 위 단언은 PopScope 없이도 통과하므로 실제 보증은 canPop == false 단언이다.
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
  });
}
