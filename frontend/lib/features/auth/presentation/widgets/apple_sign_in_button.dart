import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';

/// Apple로 시작하기 버튼. [onPressed]가 null이면 회색 비활성 외형으로 탭을 무시한다.
/// [isLoading]이 true이면 로고와 글자 대신 스피너를 보이고 탭을 무시하며, 원래 배경색을 유지한다.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tapCallback = isLoading ? null : onPressed;
    final isDisabledLook = !isLoading && onPressed == null;
    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      excludeSemantics: true,
      label: isLoading ? buttonLoadingSemanticsLabel : 'Apple로 시작하기',
      onTap: tapCallback,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tapCallback,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.actionButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDisabledLook
                ? AppColors.neutralSurface
                : AppColors.textPrimary,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: isLoading
              ? const ButtonLoadingIndicator(color: AppColors.textOnDark)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      AppAssets.appleLogoIcon,
                      width: AppLayout.smallIconSize,
                      height: AppLayout.smallIconSize,
                      // 비활성 외형에서는 회색 배경 위에서 보이도록 로고를 보조 글자색으로 칠한다.
                      colorFilter: isDisabledLook
                          ? const ColorFilter.mode(
                              AppColors.textSecondary,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'Apple로 시작하기',
                      style: AppTextStyles.body16Bold.copyWith(
                        color: isDisabledLook
                            ? AppColors.textSecondary
                            : AppColors.textOnDark,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
