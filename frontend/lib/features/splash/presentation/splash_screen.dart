import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

/// 로그인 상태를 확인하는 동안 보여 주는 화면. 첫 프레임 뒤 앱 최소버전을 검사하고 저장된 토큰 복원을 시작한다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  /// 토큰 복원 전에 최소버전을 먼저 검사한다. 업데이트가 필요하면 복원하지 않는다.
  Future<void> _start() async {
    if (!mounted) {
      return;
    }
    final isUpdateRequired = await ref
        .read(appUpdateControllerProvider.notifier)
        .check();
    if (!mounted || isUpdateRequired) {
      return;
    }
    ref.read(authFlowProvider).restore();
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
