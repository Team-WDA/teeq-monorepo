import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/features/home/presentation/widgets/call_start_button.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';
import 'package:teeq/features/home/presentation/widgets/greeting_message_card.dart';
import 'package:teeq/features/home/presentation/widgets/personality_tag_row.dart';

import '../../../../support/viewport_cases.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.horizontalMargin,
      ),
      child: Align(alignment: Alignment.topCenter, child: child),
    ),
  ),
);

const _narrowViewport = ViewportCase(width: 320, height: 568, textScale: 1.2);
const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

void main() {
  group('GreetingMessageCard', () {
    testWidgets('keeps the design height as minimum height', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(const GreetingMessageCard(message: '짧은 인사')),
      );

      expect(
        tester.getSize(find.byType(GreetingMessageCard)).height,
        AppLayout.greetingCardHeight,
      );
    });

    testWidgets('grows for the longest greeting without overflow', (
      tester,
    ) async {
      final longLine = '가' * 45;
      final message = List.filled(4, longLine).join('\n');
      await pumpAtViewport(
        tester,
        _narrowViewport,
        _wrap(GreetingMessageCard(message: message)),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(GreetingMessageCard)).height,
        greaterThan(AppLayout.greetingCardHeight),
      );
    });
  });

  group('PersonalityTagRow', () {
    testWidgets('wraps three 50 character tags at narrow width', (
      tester,
    ) async {
      final tags = ['가' * 50, '나' * 50, '다' * 50];
      await pumpAtViewport(
        tester,
        _narrowViewport,
        _wrap(PersonalityTagRow(tags: tags)),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsOneWidget);
      final tops = tester
          .widgetList(find.byType(AccentOutlineHintTag))
          .map((tag) => tester.getTopLeft(find.byWidget(tag)).dy)
          .toSet();
      expect(tops, hasLength(3));
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(AccentOutlineHintTag),
          matching: find.byType(Text),
        ),
      )) {
        expect(text.maxLines, 1);
      }
    });
  });

  group('CallStartButton', () {
    testWidgets('shows label and meets tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(CallStartButton(onPressed: () {})),
      );

      expect(find.text('통화하기'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CallStartButton)).height,
        greaterThanOrEqualTo(AppLayout.buttonHeight),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('CharacterEditEntryCard', () {
    testWidgets('shows copy, reports taps and meets guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var tapCount = 0;
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(CharacterEditEntryCard(onTap: () => tapCount += 1)),
      );

      expect(find.text('캐릭터 수정'), findsOneWidget);
      expect(find.text('캐릭터의 성향과 모습을 다시 설정할 수 있어.'), findsOneWidget);
      await tester.tap(find.byType(CharacterEditEntryCard));
      expect(tapCount, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('does not overflow at narrow width with large text', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        _narrowViewport,
        _wrap(CharacterEditEntryCard(onTap: () {})),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
