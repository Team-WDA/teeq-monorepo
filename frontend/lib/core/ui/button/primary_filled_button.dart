import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 화면 하단 등에서 쓰는 가로로 꽉 찬 주요 버튼. [onPressed]가 null이면 비활성이다.
class PrimaryFilledButton extends StatelessWidget {
  const PrimaryFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppLayout.actionButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.accent : AppColors.disabled,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppAnimationDurations.fast,
            curve: Curves.easeOut,
            style: AppTextStyles.paragraph16.copyWith(
              color: isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
