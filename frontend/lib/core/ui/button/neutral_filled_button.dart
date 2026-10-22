import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 취소·닫기처럼 보조 선택지에 쓰는 회색 채움 버튼. [onPressed]가 null이면 비활성이다.
class NeutralFilledButton extends StatelessWidget {
  const NeutralFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      label: label,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.actionButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.neutralSurface,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: Text(label, style: AppTextStyles.body16SemiBold),
        ),
      ),
    );
  }
}
