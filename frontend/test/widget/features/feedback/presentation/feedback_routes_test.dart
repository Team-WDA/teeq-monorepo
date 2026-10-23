import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/screens/call_closing_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/feedback_completion_screen.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_rating.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';

import '../../../../support/fake_auth_repository.dart';
import '../../../../support/fake_auth_status_controller.dart';
import '../../../../support/fake_splash_minimum_display_controller.dart';
import '../../../../support/fake_feedback_repository.dart';
import '../../../../support/fake_home_repository.dart';
import '../../../../support/fake_token_storage.dart';

class _FakeCurrentMemberController extends CurrentMemberController {
  @override
  Member? build() => _member;
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _summary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '안녕',
);

const _callSessionId = 'call-1';

const _firstCallStatus = FeedbackStatus(
  callIndex: 1,
  previousCallRecallRequired: false,
  requiredFeedbackSubmitted: false,
);

typedef _Harness = ({
  ProviderContainer container,
  FakeHomeRepository homeRepository,
});

/// 실제 `appRouterProvider`를 쓰는 앱을 홈 화면까지 띄운다.
Future<_Harness> _pumpApp(
  WidgetTester tester,
  FakeFeedbackRepository feedbackRepository,
) async {
  final homeRepository = FakeHomeRepository(summary: _summary);
  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      splashMinimumDisplayControllerProvider.overrideWith(
        () => FakeSplashMinimumDisplayController(true),
      ),
      appVersionProvider.overrideWith((ref) async => '0.15.0'),
      authStatusControllerProvider.overrideWith(
        () => FakeAuthStatusController(AuthStatus.signedIn),
      ),
      currentMemberControllerProvider.overrideWith(
        _FakeCurrentMemberController.new,
      ),
      homeRepositoryProvider.overrideWithValue(homeRepository),
      feedbackRepositoryProvider.overrideWithValue(feedbackRepository),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(member: _member),
      ),
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return (container: container, homeRepository: homeRepository);
}

Future<void> _goTo(
  WidgetTester tester,
  _Harness harness,
  String location,
) async {
  harness.container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('feedbackRoutes_redirectHomeWithoutFlowState', (tester) async {
    final harness = await _pumpApp(
      tester,
      FakeFeedbackRepository(status: _firstCallStatus),
    );

    for (final location in [
      AppRoutes.feedbackCompletionLocation(_callSessionId),
      AppRoutes.detailedFeedbackLocation(_callSessionId),
      AppRoutes.detailedFeedbackCompletionLocation(_callSessionId),
    ]) {
      await _goTo(tester, harness, location);

      expect(find.byType(HomeScreen), findsOneWidget, reason: location);
      expect(find.byType(FeedbackCompletionScreen), findsNothing);
    }
  });

  testWidgets('feedbackClosingRoute_rendersForSignedInMember', (tester) async {
    final harness = await _pumpApp(
      tester,
      FakeFeedbackRepository(status: _firstCallStatus),
    );

    await _goTo(
      tester,
      harness,
      AppRoutes.feedbackClosingLocation(_callSessionId),
    );

    expect(find.byType(CallClosingScreen), findsOneWidget);
    expect(find.text('이야기해서 좋았어!'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('closingToCompletion_flowEndToEnd', (tester) async {
    final feedbackRepository = FakeFeedbackRepository(status: _firstCallStatus);
    final harness = await _pumpApp(tester, feedbackRepository);
    await _goTo(
      tester,
      harness,
      AppRoutes.feedbackClosingLocation(_callSessionId),
    );

    await tester.tap(find.text('의견 남기기'));
    await tester.pumpAndSettle();
    final stars = find.descendant(
      of: find.byType(FeedbackStarRating),
      matching: find.byType(GestureDetector),
    );
    await _scrollToAndTap(tester, stars.at(3));
    await _scrollToAndTap(tester, find.text('응, 또 할래'));
    await _scrollToAndTap(tester, find.text('없었어'));
    final fetchCountBeforeSubmit = harness.homeRepository.fetchCount;

    await tester.tap(find.text('의견 보내기'));
    await tester.pumpAndSettle();

    expect(feedbackRepository.submitRequiredCalls, hasLength(1));
    expect(find.byType(FeedbackCompletionScreen), findsOneWidget);
    expect(
      harness.homeRepository.fetchCount,
      greaterThan(fetchCountBeforeSubmit),
    );

    await tester.tap(find.text('홈으로 가기'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      harness.container.read(feedbackFlowControllerProvider),
      FeedbackFlowState.initial,
    );
  });
}
