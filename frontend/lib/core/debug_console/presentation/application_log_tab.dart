import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/debug_console_filters.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/presentation/application_log_list.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_toolbar.dart';
import 'package:teeq/core/debug_console/presentation/log_level_filter_bar.dart';
import 'package:teeq/core/logging/app_log_level.dart';

/// 로그 탭: 레벨 필터가 적용된 앱 로그 목록.
class ApplicationLogTab extends ConsumerStatefulWidget {
  const ApplicationLogTab({super.key});

  @override
  ConsumerState<ApplicationLogTab> createState() => _ApplicationLogTabState();
}

class _ApplicationLogTabState extends ConsumerState<ApplicationLogTab> {
  Set<AppLogLevel> _visibleLevels = AppLogLevel.values.toSet();

  void _toggleLevel(AppLogLevel level) {
    setState(() {
      _visibleLevels = _visibleLevels.contains(level)
          ? ({..._visibleLevels}..remove(level))
          : {..._visibleLevels, level};
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(
      debugConsoleStoreProvider.select((state) => state.applicationLogs),
    );
    final visibleLogs = filterLogsByLevel(logs, _visibleLevels);
    return Column(
      children: [
        LogLevelFilterBar(
          visibleLevels: _visibleLevels,
          onLevelToggled: _toggleLevel,
        ),
        DebugConsoleToolbar(
          entryCount: visibleLogs.length,
          onCopyAll: () => copyToClipboard(
            ref,
            DebugConsoleTextFormatter.applicationLogs(visibleLogs),
          ),
          onClear: ref
              .read(debugConsoleStoreProvider.notifier)
              .clearApplicationLogs,
        ),
        Expanded(child: ApplicationLogList(logs: visibleLogs)),
      ],
    );
  }
}
