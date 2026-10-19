import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/widgets/onboarding_introduction_step_card.dart';

/// 가입을 마친 회원에게 온보딩이 시작됨을 알리는 화면.
class OnboardingIntroductionScreen extends ConsumerWidget {
  const OnboardingIntroductionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onPressed: () {
          ref
              .read(characterSetupFlowControllerProvider.notifier)
              .start(CharacterSetupMode.firstTime);
          context.go(AppRoutes.onboardingQuestions);
        },
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
