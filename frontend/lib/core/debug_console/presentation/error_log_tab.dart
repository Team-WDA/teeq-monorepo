import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/presentation/application_log_list.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_toolbar.dart';

/// 에러 탭: 에러 레벨 로그와 처리되지 않은 예외만 모아 보여 준다.
class ErrorLogTab extends ConsumerWidget {
  const ErrorLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorLogs = ref.watch(
      debugConsoleStoreProvider.select((state) => state.errorLogs),
    );
    return Column(
      children: [
        DebugConsoleToolbar(
          entryCount: errorLogs.length,
          onCopyAll: () => copyToClipboard(
            ref,
            DebugConsoleTextFormatter.applicationLogs(errorLogs),
          ),
          onClear: ref.read(debugConsoleStoreProvider.notifier).clearErrorLogs,
        ),
        Expanded(child: ApplicationLogList(logs: errorLogs)),
      ],
    );
  }
}
