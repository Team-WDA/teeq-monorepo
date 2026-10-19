import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';

import 'fake_auth_repository.dart';
import 'fake_token_storage.dart';

/// 호출 순서를 `events`에 남기는 토큰 저장소. 세션이 지워지는 시점을 알 수 있다.
class RecordingTokenStorage extends FakeTokenStorage {
  RecordingTokenStorage(this.events);

  final List<String> events;

  @override
  Future<void> clear() {
    events.add('signOut');
    return super.clear();
  }
}

class RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

class _PopRecordingObserver extends NavigatorObserver {
  _PopRecordingObserver(this.events);

  final List<String> events;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events.add('pop');
  }
}

const memberWithoutEmail = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.email,
);

/// 마이 화면과 탈퇴 모달 테스트가 함께 쓰는 실제 `AuthFlow` 구성.
class MyPageHarness {
  MyPageHarness({
    Member member = memberWithoutEmail,
    Member? fetchedMember,
    Object? fetchMeError,
    Object? deleteAccountError,
    Override? appVersionOverride,
  }) : repository = FakeAuthRepository(
         member: fetchedMember ?? member,
         fetchMeError: fetchMeError,
         deleteAccountError: deleteAccountError,
       ) {
    tokenStorage = RecordingTokenStorage(events);
    container = ProviderContainer(
      // 실패 응답이 재시도되지 않도록 한다.
      retry: (retryCount, error) => null,
      overrides: [
        appVersionOverride ??
            appVersionProvider.overrideWith((ref) async => '0.15.0'),
        authRepositoryProvider.overrideWithValue(repository),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentMemberControllerProvider.notifier).update(member);
    container.read(authStatusControllerProvider.notifier).markSignedIn();
  }

  final FakeAuthRepository repository;
  final List<String> events = [];
  final RecordingErrorHandler errorHandler = RecordingErrorHandler();
  late final RecordingTokenStorage tokenStorage;
  late final ProviderContainer container;

  Member? get currentMember => container.read(currentMemberControllerProvider);

  Widget app(Widget home) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      navigatorObservers: [_PopRecordingObserver(events)],
      home: Scaffold(body: SafeArea(child: home)),
    ),
  );
}
