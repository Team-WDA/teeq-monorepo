import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/debug_console_filters.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_empty_message.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_toolbar.dart';
import 'package:teeq/core/debug_console/presentation/network_log_detail_view.dart';
import 'package:teeq/core/debug_console/presentation/network_log_filter_bar.dart';
import 'package:teeq/core/debug_console/presentation/network_log_list_item.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';

/// 네트워크 탭: 검색·필터가 적용된 호출 목록과, 선택한 호출의 상세.
class NetworkLogTab extends ConsumerStatefulWidget {
  const NetworkLogTab({super.key});

  @override
  ConsumerState<NetworkLogTab> createState() => _NetworkLogTabState();
}

class _NetworkLogTabState extends ConsumerState<NetworkLogTab> {
  final TextEditingController _urlQueryController = TextEditingController();
  NetworkLogStatusFilter _statusFilter = NetworkLogStatusFilter.all;
  String? _selectedEntryId;

  @override
  void dispose() {
    _urlQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      debugConsoleStoreProvider.select((state) => state.networkEntries),
    );
    final selectedEntry = _findSelectedEntry(entries);
    if (selectedEntry != null) {
      return NetworkLogDetailView(
        entry: selectedEntry,
        onBack: () => setState(() => _selectedEntryId = null),
      );
    }

    final visibleEntries = filterNetworkEntries(
      entries,
      urlQuery: _urlQueryController.text,
      statusFilter: _statusFilter,
    );
    return Column(
      children: [
        NetworkLogFilterBar(
          urlQueryController: _urlQueryController,
          statusFilter: _statusFilter,
          onUrlQueryChanged: (query) => setState(() {}),
          onStatusFilterChanged: (filter) =>
              setState(() => _statusFilter = filter),
        ),
        DebugConsoleToolbar(
          entryCount: visibleEntries.length,
          onCopyAll: () => copyToClipboard(
            ref,
            DebugConsoleTextFormatter.networkEntries(visibleEntries),
          ),
          onClear: ref
              .read(debugConsoleStoreProvider.notifier)
              .clearNetworkEntries,
        ),
        Expanded(
          child: visibleEntries.isEmpty
              ? const DebugConsoleEmptyMessage()
              : ListView.separated(
                  itemCount: visibleEntries.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: AppBorderWidths.thin,
                    thickness: AppBorderWidths.thin,
                    color: AppColors.borderSubtle,
                  ),
                  itemBuilder: (context, index) {
                    final entry =
                        visibleEntries[visibleEntries.length - 1 - index];
                    return NetworkLogListItem(
                      entry: entry,
                      onPressed: () =>
                          setState(() => _selectedEntryId = entry.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 선택한 호출이 버퍼에서 밀려났거나 초기화되면 null이라 목록으로 돌아간다.
  NetworkLogEntry? _findSelectedEntry(List<NetworkLogEntry> entries) {
    final selectedId = _selectedEntryId;
    if (selectedId == null) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }
}
