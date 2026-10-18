import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/option_card/selectable_option_card.dart';

const String _longLabel = '시시콜콜한 얘기까지 다 하는 절친 시시콜콜한 얘기까지 다 하는 절친';

Widget _buildCard({
  String label = '기댈 수 있는 다정한 사이',
  bool isSelected = false,
  VoidCallback? onTap,
  double width = 345,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SelectableOptionCard(
            label: label,
            isSelected: isSelected,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}

Color? _backgroundColor(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(SelectableOptionCard),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (decoratedBox.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(_buildCard());
    await tester.pumpAndSettle();

    expect(find.text('기댈 수 있는 다정한 사이'), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(_buildCard(onTap: () => tapCount++));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectableOptionCard));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('uses soft accent background only when selected', (tester) async {
    await tester.pumpWidget(_buildCard(isSelected: false));
    await tester.pumpAndSettle();
    expect(_backgroundColor(tester), AppColors.background);

    await tester.pumpWidget(_buildCard(isSelected: true));
    await tester.pumpAndSettle();
    expect(_backgroundColor(tester), AppColors.accentSoft);
  });

  testWidgets('exposes selected semantics', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(_buildCard(isSelected: true));
    await tester.pumpAndSettle();
    final selectedData = tester
        .getSemantics(find.byType(SelectableOptionCard))
        .getSemanticsData();
    expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);
    expect(selectedData.flagsCollection.isButton, isTrue);
    expect(selectedData.label, '기댈 수 있는 다정한 사이');

    await tester.pumpWidget(_buildCard(isSelected: false));
    await tester.pumpAndSettle();
    final unselectedData = tester
        .getSemantics(find.byType(SelectableOptionCard))
        .getSemanticsData();
    expect(unselectedData.flagsCollection.isSelected, Tristate.isFalse);
    semanticsHandle.dispose();
  });

  testWidgets('long label wraps without overflow at max text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: AppLayout.maxTextScaleFactor,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 393,
              child: SelectableOptionCard(
                label: _longLabel,
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_longLabel), findsOneWidget);
  });
}
