import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';

/// 취소·닫기처럼 보조 선택지에 쓰는 회색 채움 버튼. [onPressed]가 null이면 비활성이다.
/// [isLoading]이 true이면 글자 대신 스피너를 보이고 탭을 무시한다.
class NeutralFilledButton extends StatelessWidget {
  const NeutralFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tapCallback = isLoading ? null : onPressed;
    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      excludeSemantics: true,
      label: isLoading ? buttonLoadingSemanticsLabel : label,
      onTap: tapCallback,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tapCallback,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppLayout.actionButtonHeight,
          ),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.neutralSurface,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: isLoading
              ? const ButtonLoadingIndicator(color: AppColors.textPrimary)
              : Text(label, style: AppTextStyles.body16SemiBold),
        ),
      ),
    );
  }
}
