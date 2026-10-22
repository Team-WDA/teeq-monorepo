import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/checkbox/rounded_square_checkbox.dart';

Widget _buildCheckbox({
  required bool isChecked,
  required ValueChanged<bool> onChanged,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: RoundedSquareCheckbox(
          isChecked: isChecked,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('해제 상태에서 탭하면 true를 전달한다', (tester) async {
    final received = <bool>[];
    await tester.pumpWidget(
      _buildCheckbox(isChecked: false, onChanged: received.add),
    );

    await tester.tap(find.byType(RoundedSquareCheckbox));
    await tester.pump();

    expect(received, [true]);
  });

  testWidgets('체크 상태에서 탭하면 false를 전달한다', (tester) async {
    final received = <bool>[];
    await tester.pumpWidget(
      _buildCheckbox(isChecked: true, onChanged: received.add),
    );

    await tester.tap(find.byType(RoundedSquareCheckbox));
    await tester.pump();

    expect(received, [false]);
  });
}
