import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/features/auth/presentation/login_screen.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_status_controller.dart';

void main() {
  testWidgets('기본(signedOut) 상태에서는 로그인 화면을 보여 준다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('signedIn 상태에서는 홈 화면을 보여 준다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusControllerProvider.overrideWith(
            () => FakeAuthStatusController(AuthStatus.signedIn),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('TeeQ'), findsOneWidget);
  });
}
