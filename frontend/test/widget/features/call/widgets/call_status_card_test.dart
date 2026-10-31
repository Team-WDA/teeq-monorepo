import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/call/presentation/widgets/call_card_primary_button.dart';
import 'package:teeq/features/call/presentation/widgets/call_card_secondary_button.dart';
import 'package:teeq/features/call/presentation/widgets/call_limit_info_chip.dart';
import 'package:teeq/features/call/presentation/widgets/call_status_card.dart';

import '../../../../support/viewport_cases.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.horizontalMargin,
      ),
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('calls primary and secondary callbacks', (tester) async {
    var primaryCount = 0;
    var secondaryCount = 0;
    await tester.pumpWidget(
      _wrap(
        CallStatusCard(
          title: '마이크 권한이 필요해',
          body: '티티와 대화를 시작하려면 마이크 권한을 허용해야 돼.',
          primaryLabel: '권한 허용하기',
          onPrimaryPressed: () => primaryCount++,
          secondaryLabel: '나중에 하기',
          onSecondaryPressed: () => secondaryCount++,
        ),
      ),
    );

    expect(find.text('마이크 권한이 필요해'), findsOneWidget);
    expect(find.text('티티와 대화를 시작하려면 마이크 권한을 허용해야 돼.'), findsOneWidget);

    await tester.tap(find.text('권한 허용하기'));
    expect((primaryCount, secondaryCount), (1, 0));

    await tester.tap(find.text('나중에 하기'));
    expect((primaryCount, secondaryCount), (1, 1));
  });

  testWidgets('shows a single primary button without secondary', (
    tester,
  ) async {
    var primaryCount = 0;
    await tester.pumpWidget(
      _wrap(
        CallStatusCard(
          title: '오늘 통화 시간이 다 됐어',
          body: '오늘 쓸 수 있는 통화 시간을 모두 썼어.',
          primaryLabel: '홈으로 돌아가기',
          onPrimaryPressed: () => primaryCount++,
        ),
      ),
    );

    expect(find.byType(CallCardPrimaryButton), findsOneWidget);
    expect(find.byType(CallCardSecondaryButton), findsNothing);
    await tester.tap(find.text('홈으로 돌아가기'));
    expect(primaryCount, 1);
  });

  testWidgets('uses the card buttons with the design height', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CallStatusCard(
          title: '연결하지 못했어',
          body: '네트워크 상태를 확인하고\n다시 연결해줘.',
          primaryLabel: '다시 연결하기',
          onPrimaryPressed: () {},
          secondaryLabel: '홈으로 돌아가기',
          onSecondaryPressed: () {},
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CallCardPrimaryButton)).height,
      AppLayout.callCardButtonHeight,
    );
    expect(
      tester.getSize(find.byType(CallCardSecondaryButton)).height,
      AppLayout.callCardButtonHeight,
    );
  });

  testWidgets('shows the confirmation card without body', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CallStatusCard(
          title: '통화를 마칠까?',
          primaryLabel: '계속 통화하기',
          onPrimaryPressed: () {},
          secondaryLabel: '통화 마치기',
          onSecondaryPressed: () {},
        ),
      ),
    );

    expect(find.text('통화를 마칠까?'), findsOneWidget);
    expect(find.text('계속 통화하기'), findsOneWidget);
    expect(find.text('통화 마치기'), findsOneWidget);
    expect(find.byType(CallCardSecondaryButton), findsOneWidget);
  });

  for (final viewport in viewportCases) {
    testWidgets('renders card with limit chip at ${viewport.label}', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        viewport,
        _wrap(
          CallStatusCard(
            title: '오늘 통화 시간이 다 됐어',
            body: '오늘 쓸 수 있는 통화 시간을 모두 썼어.\n내일 다시 티티랑 이야기하자!',
            primaryLabel: '피드백 남기기',
            onPrimaryPressed: () {},
            secondaryLabel: '홈으로 돌아가기',
            onSecondaryPressed: () {},
            infoChip: const CallLimitInfoChip(
              leadingText: '내일 ',
              emphasizedText: '24:00',
              trailingText: '에 통화 시간이 다시 채워져!',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CallLimitInfoChip), findsOneWidget);
    });

    testWidgets('renders body-less single-button card at ${viewport.label}', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        viewport,
        _wrap(
          CallStatusCard(
            title: '통화를 마칠까?',
            primaryLabel: '계속 통화하기',
            onPrimaryPressed: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
