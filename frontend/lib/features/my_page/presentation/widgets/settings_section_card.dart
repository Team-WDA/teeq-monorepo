import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_row.dart';

/// 섹션 제목 아래에 행들을 구분선으로 나눠 담는 설정 카드.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.rows,
    this.onTitleTap,
  });

  final String title;
  final List<SettingsRow> rows;

  /// 제목 줄을 눌렀을 때의 동작. 없으면 제목은 눌러도 반응하지 않는다.
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          // 숨겨진 이스터에그 입구라 보조기술에 버튼으로 알리지 않는다.
          excludeFromSemantics: true,
          onTap: onTitleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.settingsSectionLabelHeight,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: AppTextStyles.body14Medium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: AppColors.borderSubtle,
              width: AppBorderWidths.thin,
            ),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                    ),
                    child: Divider(
                      height: AppBorderWidths.thin,
                      thickness: AppBorderWidths.thin,
                      color: AppColors.borderSubtle,
                    ),
                  ),
                rows[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
