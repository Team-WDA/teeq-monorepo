import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/illustration/teeq_characters_illustration.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/widgets/apple_sign_in_button.dart';

/// 로그아웃 상태로 앱을 열면 처음 보는 시작 화면.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isAppleSignInInProgress = false;
  bool _isPushedRouteOpen = false;

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
              onPressed: _isAppleSignInInProgress ? null : _signInWithApple,
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
          PrimaryFilledButton(
            label: '가입하기',
            onPressed: () => _pushRoute(AppRoutes.signup),
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pushRoute(AppRoutes.login),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppLayout.minimumTapTarget,
                ),
                child: const Center(
                  child: Text(
                    '이미 계정이 있나요? 로그인하기',
                    style: AppTextStyles.caption12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pushRoute(String path) async {
    // 이동한 화면이 열려 있는 동안 연속 탭으로 중복 이동하지 않는다.
    if (_isPushedRouteOpen) {
      return;
    }
    _isPushedRouteOpen = true;
    await context.push(path);
    _isPushedRouteOpen = false;
  }

  Future<void> _signInWithApple() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isAppleSignInInProgress) {
      return;
    }
    setState(() => _isAppleSignInInProgress = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      await authFlow.signInWithApple();
    } on Object catch (error) {
      errorHandler.handle(error);
    } finally {
      if (mounted) {
        setState(() => _isAppleSignInInProgress = false);
      }
    }
  }
}

/// 일러스트와 그 뒤의 빛 번짐 3개. Figma 프레임(393폭) 기준 위치를 폭 비율로 환산한다.
class _IllustrationWithGlows extends StatelessWidget {
  const _IllustrationWithGlows();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale =
            constraints.maxWidth /
            (AppLayout.figmaFrameWidth - 2 * AppLayout.horizontalMargin);
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
