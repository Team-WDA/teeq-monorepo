import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/navigation/main_bottom_tab_bar.dart';

Widget _buildTabBar({
  required int selectedIndex,
  required ValueChanged<int> onTabSelected,
  double bottomInset = 0,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
      child: Scaffold(
        bottomNavigationBar: MainBottomTabBar(
          selectedIndex: selectedIndex,
          onTabSelected: onTabSelected,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows both tabs and selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildTabBar(selectedIndex: 1, onTabSelected: (_) {}),
    );

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('홈')),
      isSemantics(isButton: true, isSelected: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('마이')),
      isSemantics(isButton: true, isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('tap invokes onTabSelected with index', (tester) async {
    final tappedIndexes = <int>[];
    await tester.pumpWidget(
      _buildTabBar(selectedIndex: 0, onTabSelected: tappedIndexes.add),
    );

    await tester.tap(find.text('마이'));
    await tester.tap(find.text('홈'));

    expect(tappedIndexes, [1, 0]);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildTabBar(selectedIndex: 0, onTabSelected: (_) {}),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('adds bottom system inset to the content height', (tester) async {
    await tester.pumpWidget(
      _buildTabBar(selectedIndex: 0, onTabSelected: (_) {}, bottomInset: 34),
    );

    expect(
      tester.getSize(find.byType(MainBottomTabBar)).height,
      AppLayout.tabBarContentHeight + 34,
    );
  });
}
