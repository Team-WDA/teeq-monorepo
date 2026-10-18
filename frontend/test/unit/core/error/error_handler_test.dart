import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/error/error_messages.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/router/error_page_arguments.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';

import '../../../support/fake_auth_status_controller.dart';
import '../../../support/fake_home_repository.dart';
import '../../../support/fake_token_storage.dart';

const _developerMessage = 'SQL: select * from member -- 내부 정보';

ApiException _api(ErrorCode code, {int status = 400}) => ApiException(
  errorCode: code,
  httpStatus: status,
  developerMessage: _developerMessage,
);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  AuthStatus status = AuthStatus.signedIn,
  FakeTokenStorage? tokenStorage,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(
          tokenStorage ?? FakeTokenStorage(),
        ),
        authStatusControllerProvider.overrideWith(
          () => FakeAuthStatusController(status),
        ),
        homeRepositoryProvider.overrideWithValue(
          FakeHomeRepository(
            summary: const HomeSummary(
              characterName: '티티',
              personalityTags: ['다정함', '차분함', '유쾌함'],
              greeting: '안녕',
            ),
          ),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)));
}

void main() {
  testWidgets('toast 경로는 사용자 문구만 보여 주고 developerMessage는 노출하지 않는다', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    container
        .read(errorHandlerProvider)
        .handle(_api(ErrorCode.duplicateEmail, status: 409));
    await tester.pump();

    expect(container.read(toastControllerProvider), '이미 사용 중인 이메일이에요.');
    expect(find.text('이미 사용 중인 이메일이에요.'), findsOneWidget);
    expect(find.textContaining('SQL'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('errorPage 경로는 extra와 함께 /error로 이동한다', (tester) async {
    final container = await _pumpApp(tester);

    container
        .read(errorHandlerProvider)
        .handle(_api(ErrorCode.internalServerError, status: 500));
    await tester.pumpAndSettle();

    final configuration = container
        .read(appRouterProvider)
        .routerDelegate
        .currentConfiguration;
    expect(configuration.uri.path, '/error');
    final extra = configuration.extra as ErrorPageArguments;
    expect(extra.message, ErrorCode.internalServerError.userMessage);
    expect(extra.retryLocation, '/');
    expect(find.byType(ErrorScreen), findsOneWidget);
    expect(find.textContaining('SQL'), findsNothing);
  });

  testWidgets('이미 /error면 기존 retryLocation을 유지한다', (tester) async {
    // 홈(/)이 아닌 위치에서 시작해야 기본값(/)으로 되돌아가는 버그를 잡아낼 수 있다.
    final container = await _pumpApp(tester, status: AuthStatus.signedOut);
    final handler = container.read(errorHandlerProvider);

    handler.handle(const NetworkException(NetworkFailureKind.timeout));
    await tester.pumpAndSettle();
    handler.handle(const NetworkException(NetworkFailureKind.connection));
    await tester.pumpAndSettle();

    final extra =
        container
                .read(appRouterProvider)
                .routerDelegate
                .currentConfiguration
                .extra
            as ErrorPageArguments;
    expect(extra.retryLocation, '/welcome');
    expect(extra.message, networkErrorMessage);
  });

  testWidgets('다시 시도를 누르면 retryLocation으로 돌아간다', (tester) async {
    final container = await _pumpApp(tester);
    container
        .read(errorHandlerProvider)
        .handle(const NetworkException(NetworkFailureKind.timeout));
    await tester.pumpAndSettle();

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('authentication 경로는 저장소를 비우고 signedOut으로 만든다', (tester) async {
    final storage = FakeTokenStorage();
    final container = await _pumpApp(tester, tokenStorage: storage);

    container
        .read(errorHandlerProvider)
        .handle(_api(ErrorCode.expiredToken, status: 401));
    await tester.pumpAndSettle();

    expect(container.read(authStatusControllerProvider), AuthStatus.signedOut);
    expect(storage.clearCount, 1);
  });

  testWidgets('cancel DioException은 무시한다', (tester) async {
    final container = await _pumpApp(tester);

    container
        .read(errorHandlerProvider)
        .handle(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.cancel,
          ),
        );
    await tester.pump();

    expect(container.read(toastControllerProvider), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('진입점 입력: DioException이 감싼 AppException과 임의 Object', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    final handler = container.read(errorHandlerProvider);

    handler.handle(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: _api(ErrorCode.accessDenied, status: 403),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(container.read(toastControllerProvider), '접근 권한이 없어요.');

    handler.handle(StateError('boom'));
    expect(container.read(toastControllerProvider), unknownErrorMessage);

    await tester.pump(const Duration(seconds: 4));
  });
}
