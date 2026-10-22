import 'package:flutter/material.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_time_format.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 네트워크 호출 한 건을 목록에 한 줄 요약으로 보여 준다.
class NetworkLogListItem extends StatelessWidget {
  const NetworkLogListItem({
    super.key,
    required this.entry,
    required this.onPressed,
  });

  final NetworkLogEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(entry.url);
    final pathAndQuery = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    final duration = entry.duration;
    return InkWell(
      onTap: onPressed,
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
                Text(entry.method, style: AppTextStyles.body14Bold),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  _statusLabel,
                  style: AppTextStyles.body14SemiBold.copyWith(
                    color: _statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  [
                    if (duration != null) '${duration.inMilliseconds}ms',
                    formatConsoleTime(entry.startedAt),
                  ].join('  '),
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              pathAndQuery.isEmpty ? entry.url : pathAndQuery,
              style: AppTextStyles.monospace12Regular,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel => switch (entry.outcome) {
    NetworkLogOutcome.pending => '대기 중',
    _ => entry.statusCode?.toString() ?? '응답 없음',
  };

  Color get _statusColor => switch (entry.outcome) {
    NetworkLogOutcome.pending => AppColors.textMuted,
    NetworkLogOutcome.success => AppColors.accentStrong,
    NetworkLogOutcome.failure => AppColors.destructiveText,
  };
}
