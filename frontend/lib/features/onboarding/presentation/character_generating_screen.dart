import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/error/error_presentation.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/core/ui/progress/step_progress_bar.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage_illustration.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage_stepper.dart';

/// 캐릭터를 생성하는 동안 단계 연출을 보여 주는 화면.
/// 최소 연출 시간이 지나고 응답도 받았을 때만 이름 입력 화면으로 이동한다.
class CharacterGeneratingScreen extends ConsumerStatefulWidget {
  const CharacterGeneratingScreen({super.key});

  @override
  ConsumerState<CharacterGeneratingScreen> createState() =>
      _CharacterGeneratingScreenState();
}

class _CharacterGeneratingScreenState
    extends ConsumerState<CharacterGeneratingScreen>
    with SingleTickerProviderStateMixin {
  bool _isMinimumDurationElapsed = false;
  AiCharacter? _generatedCharacter;

  /// 단계 연출 전체(단계 수 × 단계 길이)를 한 번 진행한다. 끝나면 응답이 올 때까지 마지막 상태에 머문다.
  late final AnimationController _stageAnimationController =
      AnimationController(
        vsync: this,
        duration:
            AppAnimationDurations.generationStage *
            CharacterGenerationStage.values.length,
      )..addStatusListener(_handleStageAnimationStatus);

  @override
  void initState() {
    super.initState();
    _stageAnimationController.forward();
    unawaited(_generateCharacter());
  }

  @override
  void dispose() {
    _stageAnimationController.dispose();
    super.dispose();
  }

  void _handleStageAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _isMinimumDurationElapsed = true;
    _completeIfReady();
  }

  Future<void> _generateCharacter() async {
    final selections = ref
        .read(characterSetupFlowControllerProvider)
        .selections;
    try {
      // 라우터가 카탈로그가 있을 때만 이 화면에 들여보낸다.
      final catalog = ref.read(onboardingCatalogProvider).requireValue;
      _generatedCharacter = await ref
          .read(aiCharacterRepositoryProvider)
          .generate(catalog: catalog, selections: selections);
    } on Object catch (error) {
      if (mounted) {
        _handleFailure(error);
      }
      return;
    }
    if (mounted) {
      _completeIfReady();
    }
  }

  void _completeIfReady() {
    final character = _generatedCharacter;
    if (character == null || !_isMinimumDurationElapsed) {
      return;
    }
    ref
        .read(characterSetupFlowControllerProvider.notifier)
        .recordCharacter(character);
    context.go(AppRoutes.characterName);
  }

  /// 오류 표시는 중앙 핸들러에 맡긴다. 토스트로만 끝나는 오류는 7번 질문에서 다시 시도하게 돌려보낸다.
  void _handleFailure(Object error) {
    ref.read(errorHandlerProvider).handle(error);
    if (classify(AppException.from(error)) == ErrorPresentation.toast) {
      context.go(AppRoutes.onboardingQuestions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionCount = ref
        .watch(onboardingCatalogProvider)
        .requireValue
        .questions
        .length;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.horizontalMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.space24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.stepProgressBarHorizontalInset,
                  ),
                  child: StepProgressBar(
                    currentStep: questionCount,
                    totalSteps: questionCount,
                  ),
                ),
                const SizedBox(height: AppSpacing.space40),
                const ScreenTitleWithDescriptionHeading(
                  title: '거의 다 왔어.\n너의 티크 친구가 태어나고 있어!',
                  description: '네가 고른 취향을 바탕으로\n너와 잘 맞는 친구를 만들고 있어.',
                ),
                Expanded(
                  child: DesignFrameScaleBuilder(
                    designWidth: AppLayout.designContentWidth,
                    builder: (context, scale) => Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        OverflowBox(
                          minWidth: 0,
                          minHeight: 0,
                          maxWidth: AppLayout.generationGlowSize * scale,
                          maxHeight: AppLayout.generationGlowSize * scale,
                          child: SoftGlowDecoration(
                            assetPath: AppAssets.glowGeneration,
                            width: AppLayout.generationGlowSize * scale,
                            height: AppLayout.generationGlowSize * scale,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _stageAnimationController,
                          builder: (context, _) =>
                              CharacterGenerationStageIllustration(
                                progress: _stageAnimationController.value,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _stageAnimationController,
                  builder: (context, _) => CharacterGenerationStageStepper(
                    progress: _stageAnimationController.value,
                  ),
                ),
                const SizedBox(height: AppSpacing.space40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
