import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_host.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_tab_bar.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

import '../../../support/fake_developer_mode_storage.dart';

/// `MaterialApp.builder`에 호스트를 실제와 같은 방식으로 감싼 스모크 테스트 환경.
/// builder 위치에는 Overlay·Navigator가 없어, 패널이 자체 Overlay로 입력창을 쓸 수 있는지 확인한다.
Future<ProviderContainer> _pumpHost(
  WidgetTester tester, {
  required bool developerModeEnabled,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialDeveloperModeEnabledProvider.overrideWithValue(
          developerModeEnabled,
        ),
        developerModeStorageProvider.overrideWithValue(
          FakeDeveloperModeStorage(storedEnabled: developerModeEnabled),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => DebugConsoleHost(child: child!),
        home: const Scaffold(body: Text('본문')),
      ),
    ),
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(DebugConsoleHost)),
  );
}

AppLogEntry _log(String message, {AppLogLevel level = AppLogLevel.info}) =>
    AppLogEntry(
      timestamp: DateTime.utc(2026, 10, 22),
      level: level,
      name: 'Test',
      message: message,
    );

NetworkLogEntry _network(String id, String path) => NetworkLogEntry(
  id: id,
  startedAt: DateTime.utc(2026, 10, 22),
  method: 'GET',
  url: 'https://api.example.test$path',
  requestHeaders: const {'Authorization': 'Bearer raw-token'},
);

Finder get _bubble => find.byIcon(Icons.bug_report);

void main() {
  testWidgets('shows only the app while developer mode is off', (tester) async {
    await _pumpHost(tester, developerModeEnabled: false);

    expect(find.text('본문'), findsOneWidget);
    expect(_bubble, findsNothing);
  });

  testWidgets('opens the panel from the bubble and accepts search input', (
    tester,
  ) async {
    await _pumpHost(tester, developerModeEnabled: true);
    expect(_bubble, findsOneWidget);

    await tester.tap(_bubble);
    await tester.pump();
    expect(find.text('개발자 콘솔'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'api');
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lists network calls newest first and opens their detail', (
    tester,
  ) async {
    final container = await _pumpHost(tester, developerModeEnabled: true);
    final store = container.read(debugConsoleStoreProvider.notifier);
    store.recordNetworkStart(_network('1', '/api/first'));
    store.recordNetworkStart(_network('2', '/api/second'));
    await tester.tap(_bubble);
    await tester.pump();

    final firstRow = tester.getTopLeft(find.text('/api/first')).dy;
    final secondRow = tester.getTopLeft(find.text('/api/second')).dy;
    expect(secondRow, lessThan(firstRow));

    await tester.tap(find.text('/api/first'));
    await tester.pump();
    expect(
      find.textContaining('Authorization: Bearer raw-token'),
      findsOneWidget,
    );
    expect(find.byTooltip('cURL 복사'), findsOneWidget);

    await tester.tap(find.byTooltip('목록으로'));
    await tester.pump();
    expect(find.text('/api/second'), findsOneWidget);
  });

  testWidgets('shows logs, filters by level and clears the current list', (
    tester,
  ) async {
    final container = await _pumpHost(tester, developerModeEnabled: true);
    final store = container.read(debugConsoleStoreProvider.notifier);
    store.recordLog(_log('첫 로그'));
    store.recordLog(_log('둘째 로그', level: AppLogLevel.error));
    await tester.tap(_bubble);
    await tester.pump();

    await tester.tap(find.text('로그'));
    await tester.pump();
    expect(find.text('첫 로그'), findsOneWidget);
    expect(find.text('둘째 로그'), findsOneWidget);

    await tester.tap(find.text('정보'));
    await tester.pump();
    expect(find.text('첫 로그'), findsNothing);
    expect(find.text('둘째 로그'), findsOneWidget);

    await tester.tap(find.byTooltip('현재 목록 초기화'));
    await tester.pump();
    expect(find.text('기록이 없습니다'), findsOneWidget);

    // 에러 탭은 로그 탭에서 비운 것과 별개의 목록이라 에러 로그가 남아 있다.
    await tester.tap(
      find.descendant(
        of: find.byType(DebugConsoleTabBar),
        matching: find.text('에러'),
      ),
    );
    await tester.pump();
    expect(find.text('둘째 로그'), findsOneWidget);
  });

  testWidgets('copying shows a toast request and keeps the panel open', (
    tester,
  ) async {
    final container = await _pumpHost(tester, developerModeEnabled: true);
    container
        .read(debugConsoleStoreProvider.notifier)
        .recordLog(_log('복사할 로그'));
    await tester.tap(_bubble);
    await tester.pump();
    await tester.tap(find.text('로그'));
    await tester.pump();

    await tester.tap(find.byTooltip('현재 목록 전체 복사'));
    await tester.pump();

    expect(find.text('개발자 콘솔'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('closes the panel with the close button and keeps the bubble', (
    tester,
  ) async {
    await _pumpHost(tester, developerModeEnabled: true);
    await tester.tap(_bubble);
    await tester.pump();

    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();

    expect(find.text('개발자 콘솔'), findsNothing);
    expect(_bubble, findsOneWidget);
  });

  testWidgets('hardware back closes only the panel', (tester) async {
    await _pumpHost(tester, developerModeEnabled: true);
    await tester.tap(_bubble);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('개발자 콘솔'), findsNothing);
    expect(find.text('본문'), findsOneWidget);
  });

  testWidgets('tells the platform the framework handles back while the panel '
      'is open', (tester) async {
    // 예측 뒤로가기(Android 14+)는 프레임워크가 뒤로가기를 처리한다고 알린 동안만
    // 뒤로가기를 앱으로 넘긴다. 루트 화면에서도 패널을 뒤로가기로 닫으려면 알려야 한다.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final frameworkHandlesBackCalls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          frameworkHandlesBackCalls.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpHost(tester, developerModeEnabled: true);
    frameworkHandlesBackCalls.clear();

    await tester.tap(_bubble);
    await tester.pump();
    await tester.pump();

    expect(frameworkHandlesBackCalls, isNotEmpty);
    expect(frameworkHandlesBackCalls.last, isTrue);
  });

  testWidgets('keeps the dragged bubble inside the screen', (tester) async {
    await _pumpHost(tester, developerModeEnabled: true);

    await tester.drag(_bubble, const Offset(5000, 5000));
    await tester.pump();

    final bubbleRect = tester.getRect(_bubble);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(bubbleRect.right, lessThanOrEqualTo(screen.width));
    expect(bubbleRect.bottom, lessThanOrEqualTo(screen.height));
  });

  testWidgets('hides the bubble and empties the buffers when switched off', (
    tester,
  ) async {
    final container = await _pumpHost(tester, developerModeEnabled: true);
    container
        .read(debugConsoleStoreProvider.notifier)
        .recordLog(_log('사라질 로그'));

    await container.read(developerModeControllerProvider.notifier).disable();
    await tester.pump();

    expect(_bubble, findsNothing);
    expect(container.read(debugConsoleStoreProvider).applicationLogs, isEmpty);
  });
}
