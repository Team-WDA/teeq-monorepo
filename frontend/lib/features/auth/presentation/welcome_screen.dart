import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/illustration/teeq_characters_illustration.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/widgets/apple_sign_in_button.dart';
import 'package:teeq/features/auth/presentation/widgets/google_sign_in_button.dart';

/// 로그아웃 상태로 앱을 열면 처음 보는 시작 화면.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isSignInInProgress = false;

  @override
  Widget build(BuildContext context) {
    final showsAppleButton = defaultTargetPlatform == TargetPlatform.iOS;
    return BottomActionScreenLayout(
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.space40),
          ScreenTitleWithDescriptionHeading(
            title: '너랑 말이 통하는 친구,\n여기 있어.',
            description: '너의 취향에 맞는 AI 친구와 이야기해 봐.\n오늘 나눈 이야기가 다음 대화로 이어질 거야.',
          ),
          SizedBox(height: AppSpacing.space24),
          _IllustrationWithGlows(),
        ],
      ),
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showsAppleButton) ...[
            AppleSignInButton(
              onPressed: _isSignInInProgress ? null : _signInWithApple,
            ),
            const SizedBox(height: AppSpacing.space12),
          ],
          GoogleSignInButton(
            onPressed: _isSignInInProgress ? null : _signInWithGoogle,
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithApple() =>
      _signIn((authFlow) => authFlow.signInWithApple());

  Future<void> _signInWithGoogle() =>
      _signIn((authFlow) => authFlow.signInWithGoogle());

  Future<void> _signIn(
    Future<SocialSignInOutcome> Function(AuthFlow authFlow) signIn,
  ) async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isSignInInProgress) {
      return;
    }
    setState(() => _isSignInInProgress = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      final outcome = await signIn(authFlow);
      // 가입하지 않은 계정이면 약관 → 닉네임 단계로 이어간다.
      if (outcome == SocialSignInOutcome.signupRequired && mounted) {
        await context.push(AppRoutes.signupCompletion);
      }
    } on Object catch (error) {
      errorHandler.handle(error);
    } finally {
      if (mounted) {
        setState(() => _isSignInInProgress = false);
      }
    }
  }
}

/// 일러스트와 그 뒤의 빛 번짐 3개. Figma 프레임(393폭) 기준 위치를 폭 비율로 환산한다.
class _IllustrationWithGlows extends StatelessWidget {
  const _IllustrationWithGlows();

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      designWidth: AppLayout.designContentWidth,
      builder: (context, scale) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: AppLayout.glowSmallLeft * scale,
              top: AppLayout.glowSmallTop * scale,
              child: SoftGlowDecoration(
                assetPath: AppAssets.glowSmall,
                width: AppLayout.glowSmallSize * scale,
                height: AppLayout.glowSmallSize * scale,
              ),
            ),
            Positioned(
              left: AppLayout.glowMediumLeft * scale,
              top: AppLayout.glowMediumTop * scale,
              child: SoftGlowDecoration(
                assetPath: AppAssets.glowMedium,
                width: AppLayout.glowMediumSize * scale,
                height: AppLayout.glowMediumSize * scale,
              ),
            ),
            Positioned(
              left: AppLayout.glowLargeLeft * scale,
              top: AppLayout.glowLargeTop * scale,
              child: SoftGlowDecoration(
                assetPath: AppAssets.glowLarge,
                width: AppLayout.glowLargeSize * scale,
                height: AppLayout.glowLargeSize * scale,
              ),
            ),
            const TeeqCharactersIllustration(),
          ],
        );
      },
    );
  }
}
