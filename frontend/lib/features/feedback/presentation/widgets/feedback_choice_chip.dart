import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 피드백 선택지 한 칸. 선택하면 연한 라임 배경과 강조색 테두리, 굵은 글자로 바뀐다.
/// 글자가 길어지면 높이가 늘어난다.
class FeedbackChoiceChip extends StatelessWidget {
  const FeedbackChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// false이면 탭을 무시하고 글자를 흐리게 그린다.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final textStyle = isSelected
        ? AppTextStyles.body14Bold
        : AppTextStyles.body14SemiBold;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      excludeSemantics: true,
      label: label,
      onTap: isEnabled ? onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppLayout.feedbackChoiceHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space8,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSoft : AppColors.background,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.borderSubtle,
              width: AppBorderWidths.regular,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: isEnabled
                ? textStyle
                : textStyle.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
