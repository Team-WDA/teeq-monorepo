import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// Google로 시작하기 버튼. [onPressed]가 null이면 탭을 무시한다.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      label: 'Google로 시작하기',
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.socialSignInButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: AppColors.borderSubtle,
              width: AppBorderWidths.thin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.googleLogoIcon,
                width: AppLayout.smallIconSize,
                height: AppLayout.smallIconSize,
              ),
              const SizedBox(width: AppSpacing.space8),
              const Text('Google로 시작하기', style: AppTextStyles.body16Bold),
            ],
          ),
        ),
      ),
    );
  }
}
