import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 기억 문항을 평가에서 제외하는 체크 행. 탭하면 반전된 값을 [onChanged]로 알린다.
class MemoryNotApplicableCheckRow extends StatelessWidget {
  const MemoryNotApplicableCheckRow({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: isChecked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!isChecked),
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppLayout.memoryNotApplicableRowHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
          decoration: BoxDecoration(
            color: isChecked ? AppColors.accentSurface : AppColors.background,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: isChecked ? AppColors.accent : AppColors.borderSubtle,
              width: AppBorderWidths.regular,
            ),
          ),
          child: Row(
            spacing: AppSpacing.space8,
            children: [
              SvgPicture.asset(
                isChecked
                    ? AppAssets.radioCircleCheckedIcon
                    : AppAssets.radioCircleIcon,
                width: AppLayout.smallIconSize,
                height: AppLayout.smallIconSize,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space8,
                  ),
                  child: Text(
                    '기억할 만한 내용이 없어서 평가하기 어려워.',
                    style: AppTextStyles.caption12RegularMultiline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
