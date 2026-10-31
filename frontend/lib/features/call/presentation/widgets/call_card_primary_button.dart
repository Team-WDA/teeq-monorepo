import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 통화 안내 카드의 주 버튼. 강조색 채움, 높이 54, 반경 12, 16 Medium 글자다(시안 `WDA/Button/Primary`).
class CallCardPrimaryButton extends StatelessWidget {
  const CallCardPrimaryButton({
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
          decoration: const BoxDecoration(
            color: AppColors.accent,
            borderRadius: AppRadius.borderRadiusMd,
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
