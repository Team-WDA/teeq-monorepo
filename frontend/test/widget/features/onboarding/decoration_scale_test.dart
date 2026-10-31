import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';
import 'package:teeq/features/onboarding/presentation/character_generating_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_name_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_result_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../../../support/fake_ai_character_repository.dart';
import '../../../support/fake_onboarding_catalog_repository.dart';
import '../../../support/viewport_cases.dart';

class _StubAuthFlow extends Fake implements AuthFlow {}

class _StubErrorHandler extends Fake implements ErrorHandler {}

const _namedCharacter = AiCharacter(
  name: '티티',
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);
const _unnamedCharacter = AiCharacter(
  name: null,
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);
const _openDialogLabel = '팝업 열기';

ProviderContainer _createContainer({
  CharacterSetupMode mode = CharacterSetupMode.firstTime,
  AiCharacter character = _namedCharacter,
}) {
  final container = ProviderContainer(
    overrides: [
      aiCharacterRepositoryProvider.overrideWithValue(
        FakeAiCharacterRepository(generateGate: Completer<void>()),
      ),
      authFlowProvider.overrideWithValue(_StubAuthFlow()),
      errorHandlerProvider.overrideWithValue(_StubErrorHandler()),
      onboardingCatalogProvider.overrideWithValue(
        AsyncData(testOnboardingCatalog),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(characterSetupFlowControllerProvider.notifier)
    ..start(mode)
    ..recordCharacter(character);
  return container;
}

Widget _buildApp(ProviderContainer container, Widget home) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: home),
  );
}

Future<void> _pumpDialogHost(
  WidgetTester tester,
  ViewportCase viewport,
  ProviderContainer container,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => showCharacterEditConfirmationDialog(
              context,
              characterName: '티티',
              characterType: CharacterType.character3,
            ),
            child: const Text(_openDialogLabel),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await pumpAtViewport(
    tester,
    viewport,
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.tap(find.text(_openDialogLabel));
  await tester.pumpAndSettle();
}

Future<void> _pumpGeneratingScreen(
  WidgetTester tester,
  ViewportCase viewport,
  ProviderContainer container,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CharacterGeneratingScreen()),
    ],
  );
  addTearDown(router.dispose);
  await pumpAtViewport(
    tester,
    viewport,
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  // 단계 타이머가 모두 끝나도록 시간을 흘려보낸다.
  await tester.pump(AppAnimationDurations.generationStage * 4);
}

/// 테스트 컨테이너가 기록한 캐릭터(character3)의 [mood] 표정 이미지.
Finder _characterImage(CharacterMood mood) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName ==
          AppAssets.characterMoodIllustration(CharacterType.character3, mood),
);

Finder _namingCharacterImage() => _characterImage(CharacterMood.welcome);

Future<Size> _namingCharacterSizeAt(WidgetTester tester, double width) async {
  final container = _createContainer(character: _unnamedCharacter);
  await pumpAtViewport(
    tester,
    ViewportCase(width: width, height: 852, textScale: 1.0),
    _buildApp(container, const CharacterNameScreen()),
  );
  return tester.getSize(_namingCharacterImage());
}

Future<Size> _generatingGlowSizeAt(WidgetTester tester, double width) async {
  await _pumpGeneratingScreen(
    tester,
    ViewportCase(width: width, height: 852, textScale: 1.0),
    _createContainer(),
  );
  return tester.getSize(find.byType(SoftGlowDecoration));
}

void main() {
  for (final viewport in viewportCases) {
    group('viewport ${viewport.label}', () {
      testWidgets('first-time result screen renders without exception', (
        tester,
      ) async {
        await pumpAtViewport(
          tester,
          viewport,
          _buildApp(_createContainer(), const CharacterResultScreen()),
        );
        expect(tester.takeException(), isNull);
        // 가입 결과는 흐름 상태 캐릭터의 신남 표정을 그린다.
        expect(_characterImage(CharacterMood.excited), findsOneWidget);
      });

      testWidgets('edit result screen renders without exception', (
        tester,
      ) async {
        await pumpAtViewport(
          tester,
          viewport,
          _buildApp(
            _createContainer(mode: CharacterSetupMode.edit),
            const CharacterResultScreen(),
          ),
        );
        expect(tester.takeException(), isNull);
        // 수정 결과는 흐름 상태 캐릭터의 축하 표정을 그린다.
        expect(_characterImage(CharacterMood.celebrate), findsOneWidget);
      });

      testWidgets('character name screen renders without exception', (
        tester,
      ) async {
        await pumpAtViewport(
          tester,
          viewport,
          _buildApp(
            _createContainer(character: _unnamedCharacter),
            const CharacterNameScreen(),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('character generating screen renders without exception', (
        tester,
      ) async {
        await _pumpGeneratingScreen(tester, viewport, _createContainer());
        expect(tester.takeException(), isNull);
      });

      testWidgets('edit confirmation dialog renders without exception', (
        tester,
      ) async {
        await _pumpDialogHost(tester, viewport, _createContainer());
        expect(tester.takeException(), isNull);
        // 수정 확인 팝업은 호출한 쪽이 넘긴 캐릭터의 궁금 표정을 그린다.
        expect(_characterImage(CharacterMood.curious), findsOneWidget);
      });

      testWidgets('welcome screen renders without exception', (tester) async {
        await pumpAtViewport(
          tester,
          viewport,
          _buildApp(_createContainer(), const WelcomeScreen()),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('onboarding introduction screen renders without exception', (
        tester,
      ) async {
        await pumpAtViewport(
          tester,
          viewport,
          _buildApp(_createContainer(), const OnboardingIntroductionScreen()),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('decoration width scales with parent width', (tester) async {
    final sizeAtDesignWidth = await _namingCharacterSizeAt(tester, 393);
    final sizeAtWide = await _namingCharacterSizeAt(tester, 430);
    final sizeAtNarrow = await _namingCharacterSizeAt(tester, 320);

    expect(
      sizeAtDesignWidth.width,
      closeTo(AppLayout.characterNamingIllustrationSize, 0.01),
    );
    expect(
      sizeAtWide.width / sizeAtNarrow.width,
      closeTo((430 - 48) / (320 - 48), (430 - 48) / (320 - 48) * 0.01),
    );
    for (final size in [sizeAtDesignWidth, sizeAtWide, sizeAtNarrow]) {
      expect(size.width / size.height, closeTo(1, 0.001));
    }
  });

  testWidgets('generating glow scales with parent width and keeps aspect', (
    tester,
  ) async {
    final sizeAtDesignWidth = await _generatingGlowSizeAt(tester, 393);
    final sizeAtWide = await _generatingGlowSizeAt(tester, 430);
    final sizeAtNarrow = await _generatingGlowSizeAt(tester, 320);

    expect(
      sizeAtDesignWidth.width,
      closeTo(AppLayout.generationGlowSize, 0.01),
    );
    const widthRatio = (430 - 48) / (320 - 48);
    expect(sizeAtWide.width / sizeAtNarrow.width, closeTo(widthRatio, 0.014));
    for (final size in [sizeAtDesignWidth, sizeAtWide, sizeAtNarrow]) {
      expect(size.width, closeTo(size.height, 0.01));
    }
  });
}
