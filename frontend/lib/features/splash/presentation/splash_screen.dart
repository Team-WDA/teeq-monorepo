import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

/// 로그인 상태를 확인하는 동안 보여 주는 화면. 첫 프레임 뒤 저장된 토큰 복원을 시작한다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authFlowProvider).restore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SvgPicture.asset(
          AppAssets.brandLogo,
          width: AppLayout.splashLogoWidth,
          height: AppLayout.splashLogoHeight,
        ),
      ),
    );
  }
}
