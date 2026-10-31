import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 통화 안내 카드의 보조 버튼. 흰 바탕에 옅은 테두리, 높이 54, 반경 12, 16 Medium 글자다.
class CallCardSecondaryButton extends StatelessWidget {
  const CallCardSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.callCardButtonHeight,
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body16Medium,
          ),
        ),
      ),
    );
  }
}
