import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';
import 'package:teeq/features/onboarding/presentation/widgets/onboarding_introduction_step_card.dart';

/// 가입을 마친 회원에게 온보딩이 시작됨을 알리는 화면.
/// 시작 버튼은 질문 카탈로그를 불러온 뒤에만 흐름을 시작하고 질문 화면으로 이동한다.
class OnboardingIntroductionScreen extends ConsumerStatefulWidget {
  const OnboardingIntroductionScreen({super.key});

  @override
  ConsumerState<OnboardingIntroductionScreen> createState() =>
      _OnboardingIntroductionScreenState();
}

class _OnboardingIntroductionScreenState
    extends ConsumerState<OnboardingIntroductionScreen> {
  bool _isLoadingCatalog = false;

  Future<void> _startFirstTimeFlow() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isLoadingCatalog) {
      return;
    }
    setState(() => _isLoadingCatalog = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final errorHandler = ref.read(errorHandlerProvider);
    final flowController = ref.read(
      characterSetupFlowControllerProvider.notifier,
    );
    // 이전 진입에서 화면이 먼저 사라져 비우지 못한 실패 결과가 남아 있으면 새로 불러오게 한다.
    // 다시 불러오는 중인 상태도 이전 오류를 들고 있으므로 끝난 오류일 때만 비운다.
    final cachedCatalog = ref.read(onboardingCatalogProvider);
    if (cachedCatalog.hasError && !cachedCatalog.isLoading) {
      ref.invalidate(onboardingCatalogProvider);
    }
    try {
      await ref.read(onboardingCatalogProvider.future);
    } on Object catch (error) {
      errorHandler.handle(error);
      if (mounted) {
        // 실패한 결과가 캐시되므로 비워서 다음 탭에 다시 불러오게 한다.
        ref.invalidate(onboardingCatalogProvider);
        setState(() => _isLoadingCatalog = false);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    // 성공하면 화면이 곧 사라지므로 이동이 끝날 때까지 잠금을 유지한다.
    flowController.start(CharacterSetupMode.firstTime);
    context.go(AppRoutes.onboardingQuestions);
  }

  @override
  Widget build(BuildContext context) {
    return BottomActionScreenLayout(
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          const _IntroductionGlows(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.space40),
              ScreenTitleWithDescriptionHeading(
                title: '이제\n너만의 티크를\n만들 차례야!',
                description: '몇 가지 질문에 답해주면\n너와 정말 잘 맞는 친구가 탄생할 거야.',
              ),
              SizedBox(height: AppSpacing.space24),
              OnboardingIntroductionStepCard(
                iconAssetPath: AppAssets.profileSoftLimeIcon,
                message: '너에 대해 조금 더 알아보고',
              ),
              SizedBox(height: AppSpacing.space8),
              OnboardingIntroductionStepCard(
                iconAssetPath: AppAssets.heartSoftLimeIcon,
                message: '어떤 대화를 좋아하는지 말해주면',
              ),
              SizedBox(height: AppSpacing.space8),
              OnboardingIntroductionStepCard(
                iconAssetPath: AppAssets.sparklesSoftLimeIcon,
                message: '너만의 티크가 준비 돼!',
              ),
            ],
          ),
        ],
      ),
      bottomAction: PrimaryFilledButton(
        label: '나만의 티크 만들기',
        isLoading: _isLoadingCatalog,
        onPressed: _startFirstTimeFlow,
      ),
    );
  }
}

/// 카드 뒤에 깔리는 빛 번짐 2개. Figma 프레임(393폭) 기준 위치를 폭 비율로 환산한다.
class _IntroductionGlows extends StatelessWidget {
  const _IntroductionGlows();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DesignFrameScaleBuilder(
        designWidth: AppLayout.designContentWidth,
        builder: (context, scale) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: AppLayout.glowIntroductionTopLeft * scale,
                top: AppLayout.glowIntroductionTopTop * scale,
                child: SoftGlowDecoration(
                  assetPath: AppAssets.glowIntroductionTop,
                  width: AppLayout.glowIntroductionTopWidth * scale,
                  height: AppLayout.glowIntroductionTopHeight * scale,
                ),
              ),
              Positioned(
                left: AppLayout.glowIntroductionBottomLeft * scale,
                top: AppLayout.glowIntroductionBottomTop * scale,
                child: SoftGlowDecoration(
                  assetPath: AppAssets.glowIntroductionBottom,
                  width: AppLayout.glowIntroductionBottomWidth * scale,
                  height: AppLayout.glowIntroductionBottomHeight * scale,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
