import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_result_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';

import '../../../../support/fake_home_repository.dart';

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: false,
  loginType: LoginType.email,
);

AiCharacter _character(String name) => AiCharacter(
  name: name,
  characterNumber: 3,
  personalityTags: const ['다정함', '차분함', '유쾌함'],
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required CharacterSetupMode mode,
  required String name,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  container.read(characterSetupFlowControllerProvider.notifier)
    ..start(mode)
    ..recordCharacter(_character(name));
  container.read(currentMemberControllerProvider.notifier).update(_member);
  final router = GoRouter(
    initialLocation: AppRoutes.characterResult,
    routes: [
      GoRoute(
        path: AppRoutes.characterResult,
        builder: (_, _) => const CharacterResultScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('홈 스텁')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('firstTime', () {
    testWidgets('firstTime shows greeting title with copula particle', (
      tester,
    ) async {
      await _pumpScreen(tester, mode: CharacterSetupMode.firstTime, name: '티티');
      expect(find.text('반가워!\n난 티티야.'), findsOneWidget);
      expect(
        find.text('너에 대해 알게 된 내용으로 모두 준비를 마쳤어.\n앞으로 잘 부탁해!'),
        findsOneWidget,
      );
      expect(find.text('홈에서 바로 대화를 시작할 수 있어.'), findsOneWidget);
      expect(find.text('대화 시작하기'), findsOneWidget);
    });

    testWidgets('firstTime title uses final consonant form for 민준', (
      tester,
    ) async {
      await _pumpScreen(tester, mode: CharacterSetupMode.firstTime, name: '민준');
      expect(find.text('반가워!\n난 민준이야.'), findsOneWidget);
    });

    testWidgets(
      'firstTime start button updates member hasAiCharacter to true navigates '
      'home and resets flow',
      (tester) async {
        final container = await _pumpScreen(
          tester,
          mode: CharacterSetupMode.firstTime,
          name: '티티',
        );

        await tester.tap(find.text('대화 시작하기'));
        await tester.pumpAndSettle();

        expect(
          container.read(currentMemberControllerProvider),
          _member.copyWith(hasAiCharacter: true),
        );
        expect(find.text('홈 스텁'), findsOneWidget);
        expect(
          container.read(characterSetupFlowControllerProvider),
          CharacterSetupFlowState.initial,
        );
      },
    );
  });

  group('edit', () {
    testWidgets('edit shows changed title with subject particle', (
      tester,
    ) async {
      await _pumpScreen(tester, mode: CharacterSetupMode.edit, name: '티티');
      expect(find.text('티티가\n이렇게 바뀌었어!'), findsOneWidget);
      expect(find.text('수정한 내용을 반영해서\n새로운 티티의 모습으로 준비했어.'), findsOneWidget);
      expect(find.text('수정한 사항들이 모두 반영되었어!'), findsOneWidget);
      expect(find.text('홈으로 돌아가기'), findsOneWidget);
    });

    testWidgets('edit title uses final consonant form for 민준', (tester) async {
      await _pumpScreen(tester, mode: CharacterSetupMode.edit, name: '민준');
      expect(find.text('민준이\n이렇게 바뀌었어!'), findsOneWidget);
    });

    testWidgets('edit return button navigates home without changing member', (
      tester,
    ) async {
      final container = await _pumpScreen(
        tester,
        mode: CharacterSetupMode.edit,
        name: '티티',
      );

      await tester.tap(find.text('홈으로 돌아가기'));
      await tester.pumpAndSettle();

      expect(container.read(currentMemberControllerProvider), _member);
      expect(find.text('홈 스텁'), findsOneWidget);
      expect(
        container.read(characterSetupFlowControllerProvider),
        CharacterSetupFlowState.initial,
      );
    });
  });

  testWidgets('english name does not crash', (tester) async {
    await _pumpScreen(tester, mode: CharacterSetupMode.firstTime, name: 'Mina');
    expect(find.text('반가워!\n난 Mina야.'), findsOneWidget);
  });

  testWidgets('builds without throwing when flow state is reset while mounted',
      (tester) async {
    final container = await _pumpScreen(
      tester,
      mode: CharacterSetupMode.firstTime,
      name: '티티',
    );

    container.read(characterSetupFlowControllerProvider.notifier).reset();
    tester.element(find.byType(CharacterResultScreen)).markNeedsBuild();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('대화 시작하기'), findsNothing);
  });

  testWidgets('edit mode return home invalidates home summary', (tester) async {
    final repository = FakeHomeRepository(
      summary: const HomeSummary(
        characterName: '티티',
        personalityTags: ['다정함', '차분함', '유쾌함'],
        greeting: '안녕',
      ),
    );
    final container = await _pumpScreen(
      tester,
      mode: CharacterSetupMode.edit,
      name: '티티',
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    // 구독을 유지해야 autoDispose로 사라지지 않아 무효화를 검증할 수 있다.
    final subscription = container.listen(
      homeSummaryProvider(_member.memberId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(homeSummaryProvider(_member.memberId).future);
    expect(repository.fetchCount, 1);

    await tester.tap(find.text('홈으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
  });

  testWidgets('back is blocked', (tester) async {
    await _pumpScreen(tester, mode: CharacterSetupMode.firstTime, name: '티티');

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(CharacterResultScreen), findsOneWidget);
  });
}
