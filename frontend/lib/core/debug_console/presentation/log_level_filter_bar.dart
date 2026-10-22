import 'package:flutter/material.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_filter_chip.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/logging/app_log_level.dart';

/// 로그 탭의 레벨 필터. 칩을 눌러 레벨별로 보이기/숨기기를 바꾼다.
class LogLevelFilterBar extends StatelessWidget {
  const LogLevelFilterBar({
    super.key,
    required this.visibleLevels,
    required this.onLevelToggled,
  });

  final Set<AppLogLevel> visibleLevels;
  final ValueChanged<AppLogLevel> onLevelToggled;

  static const _levelLabels = {
    AppLogLevel.debug: '디버그',
    AppLogLevel.info: '정보',
    AppLogLevel.warning: '경고',
    AppLogLevel.error: '에러',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Wrap(
        spacing: AppSpacing.space8,
        children: [
          for (final level in AppLogLevel.values)
            DebugConsoleFilterChip(
              label: _levelLabels[level]!,
              isSelected: visibleLevels.contains(level),
              onPressed: () => onLevelToggled(level),
            ),
        ],
      ),
    );
  }
}
