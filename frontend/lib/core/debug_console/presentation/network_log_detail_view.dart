import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/curl_command_builder.dart';
import 'package:teeq/core/debug_console/debug_console_text_formatter.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_clipboard.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';
import 'package:teeq/core/debug_console/presentation/network_log_detail_section.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 네트워크 호출 한 건의 요청·응답 상세. 항목 복사와 cURL 복사를 제공한다.
class NetworkLogDetailView extends ConsumerWidget {
  const NetworkLogDetailView({
    super.key,
    required this.entry,
    required this.onBack,
  });

  final NetworkLogEntry entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestBody = entry.requestBody;
    final responseBody = entry.responseBody;
    final errorDescription = entry.errorDescription;
    return Column(
      children: [
        Row(
          children: [
            DebugConsoleIconActionButton(
              icon: Icons.arrow_back,
              tooltip: '목록으로',
              onPressed: () async => onBack(),
            ),
            Expanded(
              child: Text(entry.method, style: AppTextStyles.body16Bold),
            ),
            DebugConsoleIconActionButton(
              icon: Icons.copy,
              tooltip: '항목 복사',
              onPressed: () => copyToClipboard(
                ref,
                DebugConsoleTextFormatter.networkEntry(entry),
              ),
            ),
            DebugConsoleIconActionButton(
              icon: Icons.terminal,
              tooltip: 'cURL 복사',
              onPressed: () =>
                  copyToClipboard(ref, CurlCommandBuilder.build(entry)),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.space16),
            children: [
              NetworkLogDetailSection(title: '요청', text: entry.url),
              NetworkLogDetailSection(
                title: '상태',
                text: DebugConsoleTextFormatter.statusLine(entry),
              ),
              NetworkLogDetailSection(
                title: '요청 헤더',
                text: DebugConsoleTextFormatter.headersText(
                  entry.requestHeaders,
                ),
              ),
              if (requestBody != null)
                NetworkLogDetailSection(
                  title: '요청 본문',
                  text: DebugConsoleTextFormatter.bodyText(requestBody),
                ),
              NetworkLogDetailSection(
                title: '응답 헤더',
                text: DebugConsoleTextFormatter.headersText(
                  entry.responseHeaders,
                ),
              ),
              if (responseBody != null)
                NetworkLogDetailSection(
                  title: '응답 본문',
                  text: DebugConsoleTextFormatter.bodyText(responseBody),
                ),
              if (errorDescription != null)
                NetworkLogDetailSection(title: '오류', text: errorDescription),
            ],
          ),
        ),
      ],
    );
  }
}
