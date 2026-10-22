import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 로그아웃·회원 탈퇴처럼 되돌리기 어려운 동작에 쓰는 붉은 계열의 연한 채움 버튼.
/// 눈에 보이는 높이는 44이고, 터치 영역은 최소 48이 되도록 위아래에 투명 여백을 둔다.
class DestructiveTonalButton extends StatelessWidget {
  const DestructiveTonalButton({
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minimumTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppLayout.textButtonHeight,
              ),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.destructiveSurface,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Text(
                label,
                style: AppTextStyles.body16Medium.copyWith(
                  color: AppColors.destructiveText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
