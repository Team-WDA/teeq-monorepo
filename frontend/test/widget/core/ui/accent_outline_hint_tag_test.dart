import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';

const _longMessage = '아주 긴 안내 문구가 좁은 너비에서도 여러 줄로 줄바꿈되어 끝까지 보여야 한다';

Future<void> _pumpTag(WidgetTester tester, {int? maxLines}) async {
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
            width: 200,
            child: AccentOutlineHintTag(
              message: _longMessage,
              maxLines: maxLines,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'wraps to multiple lines without ellipsis when maxLines is null',
    (tester) async {
      await _pumpTag(tester);

      final text = tester.widget<Text>(find.text(_longMessage));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      final renderParagraph = tester.renderObject<RenderParagraph>(
        find.text(_longMessage),
      );
      expect(renderParagraph.didExceedMaxLines, isFalse);
      expect(
        renderParagraph.size.height,
        greaterThan(renderParagraph.text.style!.fontSize! * 1.2 * 2),
      );
    },
  );

  testWidgets('ellipsizes when maxLines is 1', (tester) async {
    await _pumpTag(tester, maxLines: 1);

    final text = tester.widget<Text>(find.text(_longMessage));
    expect(text.overflow, TextOverflow.ellipsis);
    final renderParagraph = tester.renderObject<RenderParagraph>(
      find.text(_longMessage),
    );
    expect(renderParagraph.didExceedMaxLines, isTrue);
  });
}
