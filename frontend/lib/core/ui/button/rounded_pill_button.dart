import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// [RoundedPillButton]의 채움 방식.
enum RoundedPillButtonStyle { filled, outlined }

/// 대화상자 하단 등에서 쓰는 알약형 버튼. 채움 방식은 강조색, 테두리 방식은 흰 바탕에 옅은 테두리다.
class RoundedPillButton extends StatelessWidget {
  const RoundedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = RoundedPillButtonStyle.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final RoundedPillButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final isFilled = style == RoundedPillButtonStyle.filled;
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppLayout.buttonHeight),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFilled ? AppColors.accent : AppColors.background,
            borderRadius: AppRadius.borderRadiusLg,
            border: isFilled
                ? null
                : Border.all(
                    color: AppColors.borderSubtle,
                    width: AppBorderWidths.thin,
                  ),
          ),
          child: Text(label, style: AppTextStyles.body16Bold),
        ),
      ),
    );
  }
}
