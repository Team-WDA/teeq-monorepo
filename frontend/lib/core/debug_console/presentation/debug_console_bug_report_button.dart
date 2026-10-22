import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

/// 패널 헤더의 "제보" 버튼. 로그인 상태가 아니면 흐리게 그리고, 탭하면 시트 대신 안내를 띄운다.
class DebugConsoleBugReportButton extends ConsumerWidget {
  const DebugConsoleBugReportButton({super.key, required this.onOpenSheet});

  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn =
        ref.watch(authStatusControllerProvider) == AuthStatus.signedIn;
    return DebugConsoleIconActionButton(
      icon: Icons.bug_report_outlined,
      tooltip: '제보',
      iconColor: isSignedIn ? AppColors.textPrimary : AppColors.textMuted,
      onPressed: () async {
        if (isSignedIn) {
          onOpenSheet();
          return;
        }
        ref.read(toastControllerProvider.notifier).show('로그인 후 제보할 수 있어요');
      },
    );
  }
}
