import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';

class _RecordingAuthFlow extends Fake implements AuthFlow {
  int appleSignInCount = 0;
  Object? failure;

  @override
  Future<bool> signInWithApple() async {
    appleSignInCount++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return true;
  }
}

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

Widget _buildScreen({
  double textScale = 1,
  _RecordingAuthFlow? authFlow,
  _RecordingErrorHandler? errorHandler,
}) {
  return ProviderScope(
    overrides: [
      authFlowProvider.overrideWithValue(authFlow ?? _RecordingAuthFlow()),
      errorHandlerProvider.overrideWithValue(
        errorHandler ?? _RecordingErrorHandler(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const WelcomeScreen(),
    ),
  );
}

Future<void> _withIosPlatform(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await body();
  } finally {
    // 불변식 검사가 tearDown보다 먼저 돌므로 본문 끝에서 복구한다.
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets('iOS에서는 Apple 버튼이 보인다', (tester) async {
    await _withIosPlatform(() async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Apple로 시작하기'), findsOneWidget);
    });
  });

  testWidgets('Android에서는 Apple 버튼이 없다', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Apple로 시작하기'), findsNothing);
  });

  testWidgets('가입하기와 로그인 링크가 보인다', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('가입하기'), findsOneWidget);
    expect(find.text('이미 계정이 있나요? 로그인하기'), findsOneWidget);
  });

  testWidgets('320x568, 글자 1.2배, iOS에서도 오버플로가 없다', (tester) async {
    await _withIosPlatform(() async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildScreen(textScale: 1.2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Apple로 시작하기'), findsOneWidget);
      expect(find.text('가입하기'), findsOneWidget);
    });
  });

  testWidgets('Apple 탭은 signInWithApple을 한 번 부르고 오류는 ErrorHandler로 간다', (
    tester,
  ) async {
    await _withIosPlatform(() async {
      final authFlow = _RecordingAuthFlow();
      final errorHandler = _RecordingErrorHandler();
      final failure = Exception('Apple 실패');
      authFlow.failure = failure;
      await tester.pumpWidget(
        _buildScreen(authFlow: authFlow, errorHandler: errorHandler),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apple로 시작하기'));
      await tester.pumpAndSettle();

      expect(authFlow.appleSignInCount, 1);
      expect(errorHandler.handledErrors, [failure]);
    });
  });

  testWidgets('가입하기를 연속으로 탭해도 가입 화면은 한 번만 열린다', (tester) async {
    var signupBuildCount = 0;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) {
            signupBuildCount++;
            return const Text('가입 스텁');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFlowProvider.overrideWithValue(_RecordingAuthFlow()),
          errorHandlerProvider.overrideWithValue(_RecordingErrorHandler()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가입하기'));
    await tester.tap(find.text('가입하기'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(signupBuildCount, 1);
    expect(find.text('가입 스텁'), findsOneWidget);
  });
}
