import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 설정 카드 안의 한 행. 아이콘, 라벨, 선택적 값 또는 `>`를 보여 주며 탭 동작은 없다.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.leadingIconAssetPath,
    this.value,
    this.showsChevron = false,
  });

  final String label;
  final String leadingIconAssetPath;
  final String? value;
  final bool showsChevron;

  @override
  Widget build(BuildContext context) {
    final trailingValue = value;
    return ConstrainedBox(
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
            Expanded(child: Text(label, style: AppTextStyles.body14Medium)),
            if (trailingValue != null) ...[
              const SizedBox(width: AppSpacing.space12),
              Flexible(
                child: Text(
                  trailingValue,
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
  }
}
