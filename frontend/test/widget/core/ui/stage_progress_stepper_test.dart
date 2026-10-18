import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/stage_progress_stepper.dart';

const List<String> _labels = ['성향 분석 완료', '대화 무드 반영 중', '형태 만드는 중'];

Widget _buildStepper(List<StageProgressStatus> statuses) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 321,
          child: StageProgressStepper(labels: _labels, statuses: statuses),
        ),
      ),
    ),
  );
}

int _checkIconCount(WidgetTester tester) {
  return tester
      .widgetList<SvgPicture>(find.byType(SvgPicture))
      .where(
        (picture) =>
            picture.bytesLoader.toString().contains(AppAssets.checkIcon),
      )
      .length;
}

void main() {
  testWidgets('shows all three labels', (tester) async {
    await tester.pumpWidget(
      _buildStepper(const [
        StageProgressStatus.completed,
        StageProgressStatus.inProgress,
        StageProgressStatus.pending,
      ]),
    );
    await tester.pumpAndSettle();

    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows a check icon for every completed stage', (tester) async {
    await tester.pumpWidget(
      _buildStepper(const [
        StageProgressStatus.completed,
        StageProgressStatus.completed,
        StageProgressStatus.inProgress,
      ]),
    );
    await tester.pumpAndSettle();

    expect(_checkIconCount(tester), 2);
  });

  testWidgets('pending stage keeps the muted check icon from the design', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStepper(const [
        StageProgressStatus.inProgress,
        StageProgressStatus.pending,
        StageProgressStatus.pending,
      ]),
    );
    await tester.pumpAndSettle();

    expect(_checkIconCount(tester), 2);
  });

  test('rejects labels and statuses of different length', () {
    expect(
      () => StageProgressStepper(
        labels: _labels,
        statuses: const [StageProgressStatus.completed],
      ),
      throwsAssertionError,
    );
  });
}
