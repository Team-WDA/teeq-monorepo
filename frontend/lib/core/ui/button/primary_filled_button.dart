import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';

/// 화면 하단 등에서 쓰는 가로로 꽉 찬 주요 버튼. [onPressed]가 null이면 비활성이다.
/// [isLoading]이 true이면 글자 대신 스피너를 보이고 탭을 무시하며, 활성 외형을 유지한다.
class PrimaryFilledButton extends StatelessWidget {
  const PrimaryFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = isLoading || onPressed != null;
    final tapCallback = isLoading ? null : onPressed;
    return Semantics(
      button: true,
      enabled: isEnabled && !isLoading,
      excludeSemantics: true,
      label: isLoading ? buttonLoadingSemanticsLabel : label,
      onTap: tapCallback,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tapCallback,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppLayout.actionButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.accent : AppColors.neutralSurface,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppAnimationDurations.fast,
            curve: Curves.easeOut,
            style: AppTextStyles.body16SemiBold.copyWith(
              color: isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            child: isLoading
                ? const ButtonLoadingIndicator(color: AppColors.textPrimary)
                : Text(label),
          ),
        ),
      ),
    );
  }
}
