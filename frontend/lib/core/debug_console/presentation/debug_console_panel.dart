import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/presentation/application_information_tab.dart';
import 'package:teeq/core/debug_console/presentation/application_log_tab.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel_controller.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_tab.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_tab_bar.dart';
import 'package:teeq/core/debug_console/presentation/error_log_tab.dart';
import 'package:teeq/core/debug_console/presentation/network_log_tab.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 화면 전체를 덮는 디버그 콘솔 패널. 선택된 탭 하나만 빌드한다.
class DebugConsolePanel extends ConsumerStatefulWidget {
  const DebugConsolePanel({super.key});

  @override
  ConsumerState<DebugConsolePanel> createState() => _DebugConsolePanelState();
}

class _DebugConsolePanelState extends ConsumerState<DebugConsolePanel> {
  DebugConsoleTab _selectedTab = DebugConsoleTab.network;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.space16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('개발자 콘솔', style: AppTextStyles.heading20Bold),
                  ),
                  DebugConsoleIconActionButton(
                    icon: Icons.close,
                    tooltip: '닫기',
                    onPressed: () async => ref
                        .read(debugConsolePanelControllerProvider.notifier)
                        .close(),
                  ),
                ],
              ),
            ),
            DebugConsoleTabBar(
              selectedTab: _selectedTab,
              onSelected: (tab) => setState(() => _selectedTab = tab),
            ),
            Expanded(
              child: switch (_selectedTab) {
                DebugConsoleTab.network => const NetworkLogTab(),
                DebugConsoleTab.applicationLog => const ApplicationLogTab(),
                DebugConsoleTab.error => const ErrorLogTab(),
                DebugConsoleTab.applicationInformation =>
                  const ApplicationInformationTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
