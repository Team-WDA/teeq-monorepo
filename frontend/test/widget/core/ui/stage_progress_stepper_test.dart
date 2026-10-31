import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/stage_progress_stepper.dart';

const List<String> _labels = ['성향 분석 완료', '대화 무드 반영 중', '형태 만드는 중'];

Widget _buildStepper(double progress) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 321,
          child: StageProgressStepper(labels: _labels, progress: progress),
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

/// 진행 중 단계에만 그려지는 링 이미지 개수.
int _inProgressRingCount(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .where(
        (image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName ==
                AppAssets.stageInProgressRingIcon,
      )
      .length;
}

/// 단계 원들의 상태를 왼쪽부터 읽는다. 작은 점은 진행 중, 큰 원은 색으로 완료·대기를 구분한다.
List<String> _stageStates(WidgetTester tester) {
  final circles = find.descendant(
    of: find.byType(StageProgressStepper),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    ),
  );
  return [
    for (final element in circles.evaluate())
      if (tester.getSize(find.byWidget(element.widget)).width <
          AppLayout.iconSize)
        'inProgress'
      else if (((element.widget as DecoratedBox).decoration as BoxDecoration)
              .color ==
          AppColors.accentStrong)
        'completed'
      else
        'pending',
  ];
}

double _connectorFill(WidgetTester tester, int connectorIndex) {
  final fills = tester
      .widgetList<FractionallySizedBox>(
        find.descendant(
          of: find.byType(StageProgressStepper),
          matching: find.byType(FractionallySizedBox),
        ),
      )
      .toList();
  return fills[connectorIndex].widthFactor!;
}

void main() {
  testWidgets('shows all three labels', (tester) async {
    await tester.pumpWidget(_buildStepper(0));
    await tester.pumpAndSettle();

    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('progress_0이면_진행_1칸', (tester) async {
    await tester.pumpWidget(_buildStepper(0));
    await tester.pumpAndSettle();

    expect(_stageStates(tester), ['completed', 'inProgress', 'pending']);
    expect(_inProgressRingCount(tester), 1);
    // 완료 1칸 + 대기 1칸(디자인상 흐린 체크 아이콘을 그대로 둔다).
    expect(_checkIconCount(tester), 2);
  });

  testWidgets('progress가_절반을_넘으면_단계_2가_진행', (tester) async {
    await tester.pumpWidget(_buildStepper(0.5));
    await tester.pumpAndSettle();

    expect(_stageStates(tester), ['completed', 'completed', 'inProgress']);
    expect(_checkIconCount(tester), 2);
  });

  testWidgets('progress_1이면_모두_완료', (tester) async {
    await tester.pumpWidget(_buildStepper(1));
    await tester.pumpAndSettle();

    expect(_stageStates(tester), ['completed', 'completed', 'completed']);
    expect(_inProgressRingCount(tester), 0);
    expect(_checkIconCount(tester), 3);
  });

  testWidgets('연결선_채움은_진행_구간에_비례한다', (tester) async {
    await tester.pumpWidget(_buildStepper(1 / 3));
    await tester.pumpAndSettle();
    expect(_connectorFill(tester, 0), 1);
    expect(_connectorFill(tester, 1), closeTo(0, 1e-9));

    await tester.pumpWidget(_buildStepper(1 / 2));
    await tester.pumpAndSettle();
    expect(_connectorFill(tester, 0), 1);
    expect(_connectorFill(tester, 1), closeTo(0.5, 1e-9));

    await tester.pumpWidget(_buildStepper(2 / 3));
    await tester.pumpAndSettle();
    expect(_connectorFill(tester, 1), closeTo(1, 1e-9));

    await tester.pumpWidget(_buildStepper(0));
    await tester.pumpAndSettle();
    expect(_connectorFill(tester, 0), 1);
    expect(_connectorFill(tester, 1), 0);
  });
}
