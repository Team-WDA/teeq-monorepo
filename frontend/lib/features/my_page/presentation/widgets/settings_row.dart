import 'package:flutter/material.dart';
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
    this.value,
    this.showsChevron = false,
    this.onTap,
  });

  final String label;
  final String leadingIconAssetPath;
  final String? value;
  final bool showsChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingValue = value;
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
            ),
            const SizedBox(width: AppSpacing.space12),
            // 라벨은 짧은 고정 문구라 자기 폭만 쓰고, 남는 폭은 값(또는 빈 공간)이 차지한다.
            Text(label, style: AppTextStyles.body14Medium),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: trailingValue == null
                  ? const SizedBox.shrink()
                  : Text(
                      trailingValue,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption12Medium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
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
