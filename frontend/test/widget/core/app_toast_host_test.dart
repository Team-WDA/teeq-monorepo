import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/toast/app_toast_host.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

void main() {
  testWidgets('토스트를 보여 주고 시간이 지나면 숨기며 밑줄 스타일이 새지 않는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SizedBox.shrink(),
          builder: (context, child) => AppToastHost(child: child!),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppToastHost)),
    );

    container.read(toastControllerProvider.notifier).show('알림 문구');
    await tester.pump();

    expect(find.text('알림 문구'), findsOneWidget);
    final style = DefaultTextStyle.of(tester.element(find.text('알림 문구'))).style;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(tester.widget<Text>(find.text('알림 문구')).style?.decoration, isNull);

    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
    expect(find.text('알림 문구'), findsNothing);
  });
}
