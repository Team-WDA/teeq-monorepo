import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/step_progress_bar.dart';

Widget _buildBar({required int currentStep, required int totalSteps}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: StepProgressBar(
            currentStep: currentStep,
            totalSteps: totalSteps,
          ),
        ),
      ),
    ),
  );
}

double _filledWidthFactor(WidgetTester tester) {
  return tester
      .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .widthFactor!;
}

void main() {
  testWidgets('currentStep 1 of 7 fills one seventh', (tester) async {
    await tester.pumpWidget(_buildBar(currentStep: 1, totalSteps: 7));
    await tester.pumpAndSettle();

    expect(_filledWidthFactor(tester), closeTo(1 / 7, 0.0001));
    final filledWidth = tester.getSize(find.byType(FractionallySizedBox)).width;
    expect(filledWidth, closeTo(280 / 7, 0.01));
  });

  testWidgets('7 of 7 fills the whole bar', (tester) async {
    await tester.pumpWidget(_buildBar(currentStep: 7, totalSteps: 7));
    await tester.pumpAndSettle();

    expect(_filledWidthFactor(tester), 1);
    expect(tester.getSize(find.byType(FractionallySizedBox)).width, 280);
  });

  test('rejects out of range steps', () {
    expect(
      () => StepProgressBar(currentStep: 0, totalSteps: 7),
      throwsAssertionError,
    );
    expect(
      () => StepProgressBar(currentStep: 8, totalSteps: 7),
      throwsAssertionError,
    );
    expect(
      () => StepProgressBar(currentStep: 1, totalSteps: 0),
      throwsAssertionError,
    );
  });
}
