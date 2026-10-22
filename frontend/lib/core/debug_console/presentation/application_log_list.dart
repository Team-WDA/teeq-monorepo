import 'package:flutter/material.dart';
import 'package:teeq/core/debug_console/presentation/application_log_list_item.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_empty_message.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/logging/app_log_entry.dart';

/// 앱 로그 목록(최신순). 로그 탭과 에러 탭이 함께 쓴다.
class ApplicationLogList extends StatelessWidget {
  const ApplicationLogList({super.key, required this.logs});

  /// 오래된 것에서 최신 순으로 정렬된 로그.
  final List<AppLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const DebugConsoleEmptyMessage();
    }
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, index) => const Divider(
        height: AppBorderWidths.thin,
        thickness: AppBorderWidths.thin,
        color: AppColors.borderSubtle,
      ),
      itemBuilder: (context, index) =>
          ApplicationLogListItem(entry: logs[logs.length - 1 - index]),
    );
  }
}
