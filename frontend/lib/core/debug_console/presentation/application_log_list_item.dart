import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_time_format.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

/// 앱 로그 한 건. 길게 누르면 그 항목을 복사한다.
class ApplicationLogListItem extends ConsumerStatefulWidget {
  const ApplicationLogListItem({super.key, required this.entry});

  final AppLogEntry entry;

  @override
  ConsumerState<ApplicationLogListItem> createState() =>
      _ApplicationLogListItemState();
}

class _ApplicationLogListItemState
    extends ConsumerState<ApplicationLogListItem> {
  bool _isCopying = false;

  Future<void> _copy() async {
    if (_isCopying) {
      return;
    }
    _isCopying = true;
    try {
      await copyToClipboard(
        ref,
        DebugConsoleTextFormatter.applicationLog(widget.entry),
      );
    } finally {
      _isCopying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final errorDescription = entry.errorDescription;
    final stackTraceText = entry.stackTraceText;
    return InkWell(
      onLongPress: _copy,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.level.name.toUpperCase(),
                  style: AppTextStyles.caption12SemiBold.copyWith(
                    color: _levelColor(entry.level),
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    entry.name,
                    style: AppTextStyles.caption12Medium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  formatConsoleTime(entry.timestamp),
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(entry.message, style: AppTextStyles.monospace12Regular),
            if (errorDescription != null)
              Text(
                '오류: $errorDescription',
                style: AppTextStyles.monospace12Regular.copyWith(
                  color: AppColors.destructiveText,
                ),
              ),
            if (stackTraceText != null)
              Text(
                stackTraceText,
                style: AppTextStyles.monospace12Regular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(AppLogLevel level) => switch (level) {
    AppLogLevel.debug => AppColors.textMuted,
    AppLogLevel.info => AppColors.textPrimary,
    AppLogLevel.warning => AppColors.accentStrong,
    AppLogLevel.error => AppColors.destructiveText,
  };
}
