import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';

const _longMessage = '닉네임은 나중에 언제든지 변경 가능해.';

Future<void> _pumpTag(WidgetTester tester, {required double width}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.2)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: const Center(
              child: AccentOutlineHintTag(message: _longMessage),
            ),
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(find.text(_longMessage));

/// 문단 높이가 첫 글자가 놓인 줄 하나의 높이와 같으면 한 줄이다.
bool _isSingleLine(RenderParagraph paragraph) =>
    (paragraph.size.height -
            paragraph.getFullHeightForCaret(const TextPosition(offset: 0)))
        .abs() <
    0.5;

void main() {
  testWidgets('keeps a long message on a single line and sizes the tag to the '
      'text', (tester) async {
    await _pumpTag(tester, width: 600);

    final text = tester.widget<Text>(find.text(_longMessage));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(_paragraph(tester).didExceedMaxLines, isFalse);
    expect(_isSingleLine(_paragraph(tester)), isTrue);
    expect(
      tester.getSize(find.byType(AccentOutlineHintTag)).width,
      tester.getSize(find.text(_longMessage)).width +
          AppLayout.iconSize +
          AppSpacing.space8 +
          2 * AppSpacing.space10,
    );
  });

  testWidgets('does not wrap or throw even when the tag is wider than its '
      'host', (tester) async {
    await _pumpTag(tester, width: 200);

    expect(tester.takeException(), isNull);
    expect(_isSingleLine(_paragraph(tester)), isTrue);
  });
}
