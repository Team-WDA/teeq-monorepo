import 'package:flutter/material.dart';
import 'package:teeq/core/debug_console/debug_console_filters.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_filter_chip.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 네트워크 탭의 URL 검색창과 성공/실패 필터.
class NetworkLogFilterBar extends StatelessWidget {
  const NetworkLogFilterBar({
    super.key,
    required this.urlQueryController,
    required this.statusFilter,
    required this.onUrlQueryChanged,
    required this.onStatusFilterChanged,
  });

  /// 상세 화면을 다녀와도 검색어가 남도록 호출하는 쪽이 소유한다.
  final TextEditingController urlQueryController;
  final NetworkLogStatusFilter statusFilter;
  final ValueChanged<String> onUrlQueryChanged;
  final ValueChanged<NetworkLogStatusFilter> onStatusFilterChanged;

  static const _statusLabels = {
    NetworkLogStatusFilter.all: '전체',
    NetworkLogStatusFilter.success: '성공',
    NetworkLogStatusFilter.failure: '실패',
  };

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: AppRadius.borderRadiusSm,
      borderSide: BorderSide(
        color: AppColors.borderSubtle,
        width: AppBorderWidths.thin,
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: urlQueryController,
            onChanged: onUrlQueryChanged,
            style: AppTextStyles.body14Medium,
            decoration: InputDecoration(
              isDense: true,
              hintText: '주소 검색',
              hintStyle: AppTextStyles.body14Medium.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Wrap(
            spacing: AppSpacing.space8,
            children: [
              for (final filter in NetworkLogStatusFilter.values)
                DebugConsoleFilterChip(
                  label: _statusLabels[filter]!,
                  isSelected: filter == statusFilter,
                  onPressed: () => onStatusFilterChanged(filter),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
