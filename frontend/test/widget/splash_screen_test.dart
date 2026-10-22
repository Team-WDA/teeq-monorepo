import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';

class _NoopAuthFlow extends Fake implements AuthFlow {
  @override
  Future<void> restore() async {}
}

void main() {
  testWidgets('스플래시는 화면 중앙에 브랜드 로고를 보여 준다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authFlowProvider.overrideWithValue(_NoopAuthFlow())],
        child: MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
      ),
    );

    final logoFinder = find.byType(SvgPicture);
    expect(logoFinder, findsOneWidget);
    final logoSize = tester.getSize(logoFinder);
    expect(logoSize.width, closeTo(AppLayout.splashLogoWidth, 0.01));
    expect(logoSize.height, closeTo(AppLayout.splashLogoHeight, 0.01));
    final screenCenter = tester.getCenter(find.byType(Scaffold));
    final logoCenter = tester.getCenter(logoFinder);
    expect((logoCenter - screenCenter).distance, lessThan(0.01));
  });
}
