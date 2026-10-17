import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/auth_redirect.dart';
import 'package:teeq/core/router/error_page_arguments.dart';
import 'package:teeq/features/auth/presentation/login_screen.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // 로그인 상태가 바뀌면 리다이렉트를 다시 평가하도록 알린다.
  final authStatusListenable = ValueNotifier<AuthStatus>(
    ref.read(authStatusControllerProvider),
  );
  ref.listen(authStatusControllerProvider, (previous, next) {
    authStatusListenable.value = next;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authStatusListenable,
    redirect: (context, state) =>
        authRedirect(ref.read(authStatusControllerProvider), state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) =>
            ErrorScreen(arguments: state.extra as ErrorPageArguments?),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authStatusListenable.dispose();
  });
  return router;
}
