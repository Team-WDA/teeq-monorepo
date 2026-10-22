import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 필터를 켜고 끄는 작은 칩. 선택되면 연한 강조색으로 채운다.
class DebugConsoleFilterChip extends StatelessWidget {
  const DebugConsoleFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.borderRadiusChip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : AppColors.background,
          borderRadius: AppRadius.borderRadiusChip,
          border: Border.all(
            color: isSelected ? AppColors.accentStrong : AppColors.borderSubtle,
            width: AppBorderWidths.thin,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space4,
          ),
          child: Text(label, style: AppTextStyles.caption12Medium),
        ),
      ),
    );
  }
}
