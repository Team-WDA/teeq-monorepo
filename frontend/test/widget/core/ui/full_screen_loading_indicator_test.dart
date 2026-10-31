import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/full_screen_loading_indicator.dart';

void main() {
  testWidgets('불러오는_중_접근성_라벨과_스피너를_그린다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: FullScreenLoadingIndicator()),
      ),
    );

    expect(find.bySemanticsLabel('불러오는 중'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    handle.dispose();
  });
}
