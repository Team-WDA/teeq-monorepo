import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 선택지 한 줄을 보여 주는 카드. 선택하면 연한 라임 배경과 강조색 테두리로 바뀐다.
class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: AppLayout.stepCardHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space20,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSoft : AppColors.background,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.borderSubtle,
              width: AppBorderWidths.regular,
            ),
          ),
          child: Text(label, style: AppTextStyles.body16SemiBold),
        ),
      ),
    );
  }
}
