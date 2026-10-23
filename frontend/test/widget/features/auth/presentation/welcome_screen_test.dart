import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';

class _RecordingAuthFlow extends Fake implements AuthFlow {
  int appleSignInCount = 0;
  int googleSignInCount = 0;
  Object? failure;
  SignInOutcome outcome = SignInOutcome.signedIn;

  /// 지정하면 Google 로그인이 이 값이 완료될 때까지 끝나지 않는다.
  Completer<SignInOutcome>? googleGate;

  @override
  Future<SignInOutcome> signInWithApple() async {
    appleSignInCount++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return outcome;
  }

  @override
  Future<SignInOutcome> signInWithGoogle() async {
    googleSignInCount++;
    final gate = googleGate;
    if (gate != null) {
      return gate.future;
    }
    final error = failure;
    if (error != null) {
      throw error;
    }
    return outcome;
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

  testWidgets('Google 버튼과 가입하기, 로그인하기 링크가 보인다', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Google로 시작하기'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
    expect(find.text('이미 계정이 있나요? 로그인하기'), findsOneWidget);
  });

  testWidgets('위에서부터 Apple, Google, 가입하기, 로그인하기 순서이고 간격은 8이다', (tester) async {
    await _withIosPlatform(() async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final apple = tester.getRect(find.text('Apple로 시작하기'));
      final google = tester.getRect(find.text('Google로 시작하기'));
      final signup = tester.getRect(find.text('가입하기'));
      final login = tester.getRect(find.text('이미 계정이 있나요? 로그인하기'));
      expect(apple.top, lessThan(google.top));
      expect(google.top, lessThan(signup.top));
      expect(signup.top, lessThan(login.top));

      final appleButton = tester.getRect(find.bySemanticsLabel('Apple로 시작하기'));
      final googleButton = tester.getRect(
        find.bySemanticsLabel('Google로 시작하기'),
      );
      expect(appleButton.height, AppLayout.actionButtonHeight);
      expect(googleButton.height, AppLayout.actionButtonHeight);
      expect(googleButton.top - appleButton.bottom, AppSpacing.space8);
    });
  });

  testWidgets('가입하기와 로그인하기는 각 화면을 push한다', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const Text('가입 스텁'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Text('로그인 스텁'),
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
    await tester.pumpAndSettle();
    expect(find.text('가입 스텁'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('이미 계정이 있나요? 로그인하기'));
    await tester.pumpAndSettle();
    expect(find.text('로그인 스텁'), findsOneWidget);
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
      expect(find.text('Google로 시작하기'), findsOneWidget);
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

  testWidgets('Google 탭은 signInWithGoogle을 한 번 부르고 오류는 ErrorHandler로 간다', (
    tester,
  ) async {
    final authFlow = _RecordingAuthFlow();
    final errorHandler = _RecordingErrorHandler();
    final failure = Exception('Google 실패');
    authFlow.failure = failure;
    await tester.pumpWidget(
      _buildScreen(authFlow: authFlow, errorHandler: errorHandler),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pumpAndSettle();

    expect(authFlow.googleSignInCount, 1);
    expect(errorHandler.handledErrors, [failure]);
  });

  testWidgets('가입이 필요한 계정이면 약관 화면으로 이동한다', (tester) async {
    final authFlow = _RecordingAuthFlow()
      ..outcome = SignInOutcome.signupRequired;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
        GoRoute(
          path: AppRoutes.signupCompletion,
          builder: (context, state) => const Text('약관 스텁'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFlowProvider.overrideWithValue(authFlow),
          errorHandlerProvider.overrideWithValue(_RecordingErrorHandler()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('약관 스텁'), findsOneWidget);
  });

  testWidgets('소셜 로그인이 진행 중이면 가입하기와 로그인하기는 이동하지 않는다', (tester) async {
    final gate = Completer<SignInOutcome>();
    final authFlow = _RecordingAuthFlow()..googleGate = gate;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const Text('가입 스텁'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Text('로그인 스텁'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFlowProvider.overrideWithValue(authFlow),
          errorHandlerProvider.overrideWithValue(_RecordingErrorHandler()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    await tester.tap(find.text('가입하기'));
    await tester.pump();
    await tester.tap(find.text('이미 계정이 있나요? 로그인하기'));
    await tester.pumpAndSettle();

    expect(find.text('가입 스텁'), findsNothing);
    expect(find.text('로그인 스텁'), findsNothing);

    gate.complete(SignInOutcome.signedIn);
    await tester.pumpAndSettle();
  });

  testWidgets('취소하면 화면에 머물고 오류도 없다', (tester) async {
    final authFlow = _RecordingAuthFlow()..outcome = SignInOutcome.cancelled;
    final errorHandler = _RecordingErrorHandler();
    await tester.pumpWidget(
      _buildScreen(authFlow: authFlow, errorHandler: errorHandler),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(errorHandler.handledErrors, isEmpty);
  });
}
