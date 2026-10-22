import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/bottom_sheet/app_bottom_sheet.dart';

const _sheetContentKey = Key('sheetContent');
const _openButtonKey = Key('openSheetButton');

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  bool isDismissible = true,
  bool enableDrag = true,
  ValueChanged<String?>? onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: _openButtonKey,
              onPressed: () async {
                final result = await showAppBottomSheet<String>(
                  context: context,
                  isDismissible: isDismissible,
                  enableDrag: enableDrag,
                  builder: (sheetContext) => SizedBox(
                    key: _sheetContentKey,
                    height: 300,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext, 'result'),
                      child: const Text('결과 반환'),
                    ),
                  ),
                );
                onClosed?.call(result);
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dismissibleSheet_closesWhenBarrierTapped', (tester) async {
    await _pumpSheetHost(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetContentKey), findsNothing);
  });

  testWidgets('dismissibleSheet_closesOnBackNavigation', (tester) async {
    await _pumpSheetHost(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetContentKey), findsNothing);
  });

  testWidgets('nonDismissibleSheet_staysOpenWhenBarrierTapped', (tester) async {
    await _pumpSheetHost(tester, isDismissible: false, enableDrag: false);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetContentKey), findsOneWidget);
  });

  testWidgets('nonDismissibleSheet_staysOpenOnBackNavigation', (tester) async {
    await _pumpSheetHost(tester, isDismissible: false, enableDrag: false);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetContentKey), findsOneWidget);
  });

  testWidgets('nonDismissibleSheet_staysOpenWhenDraggedDown', (tester) async {
    await _pumpSheetHost(tester, isDismissible: false, enableDrag: false);

    await tester.drag(find.byKey(_sheetContentKey), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetContentKey), findsOneWidget);
  });

  testWidgets('sheet_returnsResultViaNavigatorPop', (tester) async {
    String? closedResult;
    await _pumpSheetHost(tester, onClosed: (result) => closedResult = result);

    await tester.tap(find.text('결과 반환'));
    await tester.pumpAndSettle();

    expect(closedResult, 'result');
  });

  testWidgets('sheet_showsHandleWithTokenSize', (tester) async {
    await _pumpSheetHost(tester);

    final handleFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.width == AppLayout.sheetHandleWidth &&
          widget.height == AppLayout.sheetHandleHeight,
    );

    expect(handleFinder, findsOneWidget);
    expect(
      tester.getSize(handleFinder),
      const Size(AppLayout.sheetHandleWidth, AppLayout.sheetHandleHeight),
    );
  });
}
