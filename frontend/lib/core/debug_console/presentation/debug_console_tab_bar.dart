import 'package:flutter/material.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_tab.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 패널 위쪽의 탭 막대. 선택된 탭 아래에 강조 밑줄을 긋는다.
class DebugConsoleTabBar extends StatelessWidget {
  const DebugConsoleTabBar({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final DebugConsoleTab selectedTab;
  final ValueChanged<DebugConsoleTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in DebugConsoleTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == selectedTab
                          ? AppColors.accentStrong
                          : AppColors.borderSubtle,
                      width: AppBorderWidths.progress,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space12,
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body14SemiBold.copyWith(
                      color: tab == selectedTab
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
