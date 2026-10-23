import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 설정 카드 안의 한 행. 아이콘, 라벨, 선택적 값 또는 `>`를 보여 준다. [onTap]이 있을 때만 탭할 수 있다.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.leadingIconAssetPath,
    this.leadingIconColor,
    this.value,
    this.showsChevron = false,
    this.isLabelBold = false,
    this.onTap,
  });

  final String label;
  final String leadingIconAssetPath;

  /// 단색으로 칠할 아이콘 색. 없으면 에셋 원래 색을 쓴다(예: 흰색 Apple 로고를 어두운 색으로 바꿀 때).
  final Color? leadingIconColor;
  final String? value;
  final bool showsChevron;

  /// 라벨을 굵게 보여 준다(로그인 방식처럼 강조할 문구).
  final bool isLabelBold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingValue = value;
    final iconColor = leadingIconColor;
    final labelText = Text(
      label,
      style: isLabelBold
          ? AppTextStyles.body14Bold
          : AppTextStyles.body14Medium,
    );
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.settingsRowHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              leadingIconAssetPath,
              width: AppLayout.iconSize,
              height: AppLayout.iconSize,
              colorFilter: iconColor == null
                  ? null
                  : ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.space12),
            // 값이 있는 행의 라벨은 짧은 고정 문구라 자기 폭만 쓰고, 남는 폭은 값이 차지한다.
            // 값이 없는 행의 라벨(로그인 방식 등)은 남는 폭 안에서 줄바꿈한다.
            if (trailingValue == null)
              Expanded(child: labelText)
            else ...[
              labelText,
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  trailingValue,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (showsChevron) ...[
              const SizedBox(width: AppSpacing.space12),
              SvgPicture.asset(
                AppAssets.chevronRightIcon,
                width: AppLayout.iconSize,
                height: AppLayout.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final tapCallback = onTap;
    if (tapCallback == null) {
      return content;
    }
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: trailingValue == null ? label : '$label $trailingValue',
      onTap: tapCallback,
      child: InkWell(onTap: tapCallback, child: content),
    );
  }
}
