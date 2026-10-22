import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';

import '../support/fake_app_update_controller.dart';

class _RecordingAuthFlow extends Fake implements AuthFlow {
  _RecordingAuthFlow(this.events);

  final List<String> events;

  @override
  Future<void> restore() async {
    events.add('restore');
  }
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  required List<String> events,
  AppUpdateRequirement? requirement,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authFlowProvider.overrideWithValue(_RecordingAuthFlow(events)),
        appUpdateControllerProvider.overrideWith(
          () => FakeAppUpdateController(
            requirement: requirement,
            onCheck: () => events.add('check'),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('스플래시는 화면 중앙에 브랜드 로고를 보여 준다', (tester) async {
    await _pumpSplash(tester, events: []);

    final logoFinder = find.byType(SvgPicture);
    expect(logoFinder, findsOneWidget);
    final logoSize = tester.getSize(logoFinder);
    expect(logoSize.width, closeTo(AppLayout.splashLogoWidth, 0.01));
    expect(logoSize.height, closeTo(AppLayout.splashLogoHeight, 0.01));
    final screenCenter = tester.getCenter(find.byType(Scaffold));
    final logoCenter = tester.getCenter(logoFinder);
    expect((logoCenter - screenCenter).distance, lessThan(0.01));
  });

  testWidgets('업데이트가 필요 없으면 버전 검사 뒤에 토큰 복원을 시작한다', (tester) async {
    final events = <String>[];

    await _pumpSplash(tester, events: events);

    expect(events, ['check', 'restore']);
  });

  testWidgets('업데이트가 필요하면 토큰 복원을 시작하지 않는다', (tester) async {
    final events = <String>[];

    await _pumpSplash(
      tester,
      events: events,
      requirement: const AppUpdateRequirement(
        minimumVersion: '1.3.0',
        storeUrl: 'https://store.example.test',
      ),
    );

    expect(events, ['check']);
  });
}
