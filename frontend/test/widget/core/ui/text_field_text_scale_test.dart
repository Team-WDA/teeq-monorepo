import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/text_field/outlined_box_text_field.dart';
import 'package:teeq/core/ui/text_field/underline_labeled_text_field.dart';

Widget _buildScaled(Widget field) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.2)),
      child: child!,
    ),
    home: Scaffold(body: field),
  );
}

void main() {
  testWidgets('밑줄 입력 필드는 글자 1.2배에서도 예외 없이 최소 높이 이상이다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      _buildScaled(
        UnderlineLabeledTextField(
          label: '이메일',
          hintText: '입력',
          controller: controller,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final fieldHeight = tester.getSize(find.byType(TextField)).height;
    expect(fieldHeight, greaterThanOrEqualTo(AppLayout.inputFieldHeight));
  });

  testWidgets('박스 입력 필드는 글자 1.2배에서도 예외 없이 최소 높이 이상이다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      _buildScaled(
        OutlinedBoxTextField(hintText: '입력', controller: controller),
      ),
    );

    expect(tester.takeException(), isNull);
    final boxHeight = tester
        .getSize(
          find.descendant(
            of: find.byType(OutlinedBoxTextField),
            matching: find.byType(ConstrainedBox).last,
          ),
        )
        .height;
    expect(boxHeight, greaterThanOrEqualTo(AppLayout.outlinedInputHeight));
  });
}
