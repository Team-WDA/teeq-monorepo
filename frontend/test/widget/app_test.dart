import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/presentation/login_screen.dart';
import 'package:teeq/features/auth/presentation/signup_completion_screen.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_auth_status_controller.dart';
import '../support/fake_token_storage.dart';

class _FakeCurrentMemberController extends CurrentMemberController {
  _FakeCurrentMemberController(this._initialMember);

  final Member? _initialMember;

  @override
  Member? build() => _initialMember;
}

Future<void> _pumpSignedInApp(WidgetTester tester, Member member) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStatusControllerProvider.overrideWith(
          () => FakeAuthStatusController(AuthStatus.signedIn),
        ),
        currentMemberControllerProvider.overrideWith(
          () => _FakeCurrentMemberController(member),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signedOut 상태에서는 로그인 화면을 보여 준다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusControllerProvider.overrideWith(
            () => FakeAuthStatusController(AuthStatus.signedOut),
          ),
        ],
        child: const App(),
      ),
    );
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

  testWidgets('signedIn + 가입 미완료 회원이면 가입 완료 화면을 보여 준다', (tester) async {
    await _pumpSignedInApp(
      tester,
      const Member(
        memberId: 'member-1',
        hasAiCharacter: false,
        loginType: LoginType.apple,
      ),
    );

    expect(find.byType(SignupCompletionScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('signedIn + 가입 완료 회원이면 홈 화면을 보여 준다', (tester) async {
    await _pumpSignedInApp(
      tester,
      const Member(
        memberId: 'member-1',
        nickname: '티큐',
        hasAiCharacter: false,
        loginType: LoginType.apple,
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignupCompletionScreen), findsNothing);
  });

  testWidgets('빈 저장소로 unknown에서 시작하면 스플래시 복원 뒤 로그인 화면을 보여 준다', (tester) async {
    final tokenStorage = FakeTokenStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tokenStorage.readCount, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
