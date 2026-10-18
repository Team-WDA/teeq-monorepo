import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_name_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';

import '../../../../support/fake_ai_character_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _unnamed = AiCharacter(
  name: null,
  characterNumber: 3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);
const _named = AiCharacter(
  name: '티티',
  characterNumber: 3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);

class _Harness {
  _Harness(this.container, this.repository, this.errorHandler);

  final ProviderContainer container;
  final FakeAiCharacterRepository repository;
  final _RecordingErrorHandler errorHandler;
}

Future<_Harness> _pumpScreen(
  WidgetTester tester,
  FakeAiCharacterRepository repository, {
  AiCharacter character = _unnamed,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    overrides: [
      aiCharacterRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  container.read(characterSetupFlowControllerProvider.notifier)
    ..start(CharacterSetupMode.firstTime)
    ..recordCharacter(character);
  final router = GoRouter(
    initialLocation: AppRoutes.characterName,
    routes: [
      GoRoute(
        path: AppRoutes.characterName,
        builder: (_, _) => const CharacterNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.characterResult,
        builder: (_, _) => const Text('결과 스텁'),
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
  await tester.pumpAndSettle();
  return _Harness(container, repository, errorHandler);
}

VoidCallback? _startButtonOnPressed(WidgetTester tester) => tester
    .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
    .onPressed;

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
}

void main() {
  testWidgets('button disabled below two characters and enabled at two', (
    tester,
  ) async {
    await _pumpScreen(tester, FakeAiCharacterRepository());

    expect(_startButtonOnPressed(tester), isNull);
    await _enterName(tester, '가');
    expect(_startButtonOnPressed(tester), isNull);
    await _enterName(tester, '가나');
    expect(_startButtonOnPressed(tester), isNotNull);
  });

  testWidgets('button disabled while only a lone jamo is entered', (
    tester,
  ) async {
    await _pumpScreen(tester, FakeAiCharacterRepository());

    await _enterName(tester, 'ㄱ');
    expect(_startButtonOnPressed(tester), isNull);
    await _enterName(tester, '가나');
    expect(_startButtonOnPressed(tester), isNotNull);
  });

  testWidgets('rejects characters outside hangul letters digits and limits '
      'to ten', (tester) async {
    await _pumpScreen(tester, FakeAiCharacterRepository());

    await _enterName(tester, 'a!b c');
    expect(_fieldText(tester), 'abc');

    await _enterName(tester, '가나다라마바사아자차카');
    expect(_fieldText(tester), '가나다라마바사아자차');
  });

  testWidgets('prefills current name in edit scenario', (tester) async {
    await _pumpScreen(tester, FakeAiCharacterRepository(), character: _named);

    expect(_fieldText(tester), '티티');
    expect(_startButtonOnPressed(tester), isNotNull);
  });

  testWidgets('submit calls confirmName once even when tapped twice quickly', (
    tester,
  ) async {
    final gate = Completer<void>();
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(
        confirmNameGate: gate,
        confirmNameResult: _named,
      ),
    );
    await _enterName(tester, '티티');

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pump();

    expect(harness.repository.confirmedNames, ['티티']);
    expect(_startButtonOnPressed(tester), isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('submit success records character and navigates to result', (
    tester,
  ) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(confirmNameResult: _named),
    );
    await _enterName(tester, '티티');

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('결과 스텁'), findsOneWidget);
    expect(
      harness.container.read(characterSetupFlowControllerProvider).character,
      _named,
    );
  });

  testWidgets('second tap after successful submit does not send another '
      'confirmName call', (tester) async {
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(confirmNameResult: _named),
    );
    await _enterName(tester, '티티');

    final staleOnPressed = _startButtonOnPressed(tester)!;
    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pump();
    // 이동이 끝나기 전에 남아 있던 버튼 콜백이 한 번 더 불리는 상황.
    staleOnPressed();
    await tester.pumpAndSettle();

    expect(harness.repository.confirmedNames, ['티티']);
    expect(find.text('결과 스텁'), findsOneWidget);
  });

  testWidgets('submit failure reports error keeps screen and allows resubmit', (
    tester,
  ) async {
    final failure = Exception('이름 확정 실패');
    final harness = await _pumpScreen(
      tester,
      FakeAiCharacterRepository(confirmNameError: failure),
    );
    await _enterName(tester, '티티');

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, [failure]);
    expect(find.byType(CharacterNameScreen), findsOneWidget);
    expect(_startButtonOnPressed(tester), isNotNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();
    expect(harness.repository.confirmedNames, ['티티', '티티']);
  });

  testWidgets('back button is blocked', (tester) async {
    await _pumpScreen(tester, FakeAiCharacterRepository());

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(CharacterNameScreen), findsOneWidget);
  });
}
