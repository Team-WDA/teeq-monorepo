import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
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
    testWidgets('height follows the number of text lines', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(const GreetingMessageCard(message: '한 줄')),
      );
      final oneLineHeight = tester
          .getSize(find.byType(GreetingMessageCard))
          .height;
      final oneLineTextHeight = tester.getSize(find.text('한 줄')).height;

      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(const GreetingMessageCard(message: '첫째 줄\n둘째 줄')),
      );
      final twoLineHeight = tester
          .getSize(find.byType(GreetingMessageCard))
          .height;

      expect(oneLineHeight, AppSpacing.space24 * 2 + oneLineTextHeight);
      expect(twoLineHeight, greaterThan(oneLineHeight));
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
      final longHeight = tester
          .getSize(find.byType(GreetingMessageCard))
          .height;
      await pumpAtViewport(
        tester,
        _narrowViewport,
        _wrap(const GreetingMessageCard(message: '한 줄')),
      );
      expect(
        longHeight,
        greaterThan(tester.getSize(find.byType(GreetingMessageCard)).height),
      );
    });
  });

  group('PersonalityTagRow', () {
    testWidgets('wraps between tags without wrapping inside a tag', (
      tester,
    ) async {
      final tags = ['다정다감한 친구', '공감과 조언을', '티키타카가 좋은'];
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
      expect(tops.length, greaterThanOrEqualTo(2));
      for (final tag in tags) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(tag));
        final lineHeight = paragraph.getFullHeightForCaret(
          const TextPosition(offset: 0),
        );
        expect(paragraph.size.height, lessThan(lineHeight * 1.5));
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
