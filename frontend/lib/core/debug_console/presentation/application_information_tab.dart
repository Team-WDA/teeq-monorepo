import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/presentation/application_information_row.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';
import 'package:teeq/core/debug_console/presentation/developer_mode_disable_button.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/router/app_router.dart';

/// 앱 정보 탭: 버전, API 서버, 운영체제, 현재 라우트와 개발자 모드 끄기.
class ApplicationInformationTab extends ConsumerWidget {
  const ApplicationInformationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionProvider).value;
    final apiBaseUrl = ref.watch(appConfigProvider).apiBaseUrl;
    final operatingSystem =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final route = ref
        .watch(appRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('앱 정보', style: AppTextStyles.body16Bold),
            ),
            DebugConsoleIconActionButton(
              icon: Icons.copy,
              tooltip: '앱 정보 복사',
              onPressed: () => copyToClipboard(
                ref,
                DebugConsoleTextFormatter.applicationInformation(
                  appVersion: appVersion,
                  apiBaseUrl: apiBaseUrl,
                  operatingSystem: operatingSystem,
                  route: route,
                ),
              ),
            ),
          ],
        ),
        ApplicationInformationRow(label: '앱 버전', value: appVersion ?? '알 수 없음'),
        ApplicationInformationRow(label: 'API 서버', value: apiBaseUrl),
        ApplicationInformationRow(label: '운영체제', value: operatingSystem),
        ApplicationInformationRow(label: '현재 라우트', value: route),
        const SizedBox(height: AppSpacing.space24),
        const DeveloperModeDisableButton(),
      ],
    );
  }
}
