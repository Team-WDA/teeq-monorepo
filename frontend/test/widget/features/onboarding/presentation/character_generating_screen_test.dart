import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_generating_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';

import '../../../../support/fake_ai_character_repository.dart';
import '../../../../support/fake_onboarding_catalog_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _generated = AiCharacter(
  name: null,
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);
const _stageTwoMessage = '말투와 분위기를 맞추고 있어.';
const _stageThreeMessage = '마지막 형태를 다듬는 중!';
const _fullTimeline = Duration(seconds: 9);

class _Harness {
  _Harness(this.container, this.repository, this.errorHandler);

  final ProviderContainer container;
  final FakeAiCharacterRepository repository;
  final _RecordingErrorHandler errorHandler;
}

Future<_Harness> _pumpScreen(
  WidgetTester tester,
  FakeAiCharacterRepository repository,
) async {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    overrides: [
      aiCharacterRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
      onboardingCatalogRepositoryProvider.overrideWithValue(
        FakeOnboardingCatalogRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(onboardingCatalogProvider.future);
  final controller = container.read(
    characterSetupFlowControllerProvider.notifier,
  )..start(CharacterSetupMode.firstTime);
  for (final question in testOnboardingCatalog.questions) {
    controller.toggleOption(question, question.options.first);
  }
  final router = GoRouter(
    initialLocation: AppRoutes.onboardingGenerating,
    routes: [
      GoRoute(
        path: AppRoutes.onboardingGenerating,
        builder: (_, _) => const CharacterGeneratingScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (_, _) => const Text('질문 스텁'),
      ),
      GoRoute(
        path: AppRoutes.characterName,
        builder: (_, _) => const Text('이름 스텁'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  return _Harness(container, repository, errorHandler);
}

void main() {
  testWidgets('calls generate once with selected answers on entry', (
    tester,
  ) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateResult: _generated),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(harness.repository.generateCalls, hasLength(1));
    final call = harness.repository.generateCalls.single;
    expect(
      call.selections,
      harness.container.read(characterSetupFlowControllerProvider).selections,
    );
    expect(call.catalog, same(testOnboardingCatalog));
    await tester.pump(_fullTimeline);
    await tester.pumpAndSettle();
  });

  testWidgets('1단계에는_말풍선이_없다', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        generateGate: Completer<void>(),
        generateResult: _generated,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text(_stageTwoMessage), findsNothing);
    expect(find.text(_stageThreeMessage), findsNothing);
  });

  testWidgets('말풍선은_2단계와_3단계에서_같은_위치에_있다', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        generateGate: Completer<void>(),
        generateResult: _generated,
      ),
    );

    // 2단계 가운데(4.5초)와 3단계 가운데(7.5초)에서 말풍선 위치를 잰다.
    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.text(_stageTwoMessage), findsOneWidget);
    expect(find.text(_stageThreeMessage), findsNothing);
    final stageTwoTop = tester.getTopLeft(find.text(_stageTwoMessage)).dy;

    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text(_stageTwoMessage), findsNothing);
    expect(find.text(_stageThreeMessage), findsOneWidget);
    final stageThreeTop = tester.getTopLeft(find.text(_stageThreeMessage)).dy;

    expect(stageThreeTop, stageTwoTop);
  });

  testWidgets('9초_전에_응답이_와도_애니메이션이_끝날_때까지_머문다', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateResult: _generated),
    );

    await tester.pump(const Duration(milliseconds: 8999));
    await tester.pump();
    expect(find.text('이름 스텁'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('이름 스텁'), findsOneWidget);
  });

  testWidgets('응답이_9초_뒤에_오면_마지막_단계에서_대기한다', (tester) async {
    final gate = Completer<void>();
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateGate: gate, generateResult: _generated),
    );

    await tester.pump(_fullTimeline);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('이름 스텁'), findsNothing);
    expect(find.text(_stageTwoMessage), findsNothing);
    expect(find.text(_stageThreeMessage), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('이름 스텁'), findsOneWidget);
  });

  testWidgets('제목에_티크가_들어간다', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        generateGate: Completer<void>(),
        generateResult: _generated,
      ),
    );

    expect(find.text('거의 다 왔어.\n너의 티크 친구가 태어나고 있어!'), findsOneWidget);
    expect(find.textContaining('티큐'), findsNothing);
  });

  testWidgets('records generated character in flow state before navigating', (
    tester,
  ) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateResult: _generated),
    );
    expect(
      harness.container.read(characterSetupFlowControllerProvider).character,
      isNull,
    );

    await tester.pump(_fullTimeline);
    await tester.pumpAndSettle();

    expect(
      harness.container.read(characterSetupFlowControllerProvider).character,
      _generated,
    );
  });

  testWidgets('생성이_실패하면_질문_화면으로_돌아가고_컨트롤러가_정리된다', (tester) async {
    const failure = ApiException(
      errorCode: ErrorCode.aiServerUnavailable,
      httpStatus: 502,
    );
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateError: failure),
    );
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, [failure]);
    expect(find.text('질문 스텁'), findsOneWidget);
    // 화면이 정리될 때 애니메이션 컨트롤러도 해제되어 예외가 남지 않는다.
    expect(find.byType(CharacterGeneratingScreen), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      harness.container
          .read(characterSetupFlowControllerProvider)
          .selections
          .isComplete(testOnboardingCatalog),
      isTrue,
    );
  });

  testWidgets('network failure reports error and does not navigate itself', (
    tester,
  ) async {
    const failure = NetworkException(NetworkFailureKind.connection);
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(generateError: failure),
    );
    await tester.pump(_fullTimeline);
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, [failure]);
    expect(find.text('질문 스텁'), findsNothing);
    expect(find.text('이름 스텁'), findsNothing);
    expect(find.byType(CharacterGeneratingScreen), findsOneWidget);
  });

  testWidgets('back button is blocked', (tester) async {
    await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        generateGate: Completer<void>(),
        generateResult: _generated,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(CharacterGeneratingScreen), findsOneWidget);
  });
}
