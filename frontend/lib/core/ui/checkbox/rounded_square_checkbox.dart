import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';

/// 모서리가 둥근 정사각형 체크박스. 탭하면 반전된 값을 [onChanged]로 알린다.
class RoundedSquareCheckbox extends StatelessWidget {
  const RoundedSquareCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fillColor = isChecked ? AppColors.accent : AppColors.background;
    return Semantics(
      button: true,
      checked: isChecked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!isChecked),
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: Curves.easeOut,
          width: AppLayout.checkboxSize,
          height: AppLayout.checkboxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: AppRadius.borderRadiusXs,
            border: Border.all(
              color: isChecked ? AppColors.accent : AppColors.textMuted,
              width: AppBorderWidths.thin,
            ),
          ),
          child: isChecked
              ? SizedBox(
                  width: AppLayout.smallIconSize,
                  height: AppLayout.smallIconSize,
                  child: Center(child: SvgPicture.asset(AppAssets.checkIcon)),
                )
              : null,
        ),
      ),
    );
  }
}
