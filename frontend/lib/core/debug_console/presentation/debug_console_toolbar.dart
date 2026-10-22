import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';

/// 목록 위의 도구 줄: 건수, 현재 목록 전체 복사, 현재 목록 초기화.
class DebugConsoleToolbar extends StatelessWidget {
  const DebugConsoleToolbar({
    super.key,
    required this.entryCount,
    required this.onCopyAll,
    required this.onClear,
  });

  final int entryCount;
  final Future<void> Function() onCopyAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$entryCount건',
              style: AppTextStyles.caption12Medium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          DebugConsoleIconActionButton(
            icon: Icons.copy,
            tooltip: '현재 목록 전체 복사',
            onPressed: onCopyAll,
          ),
          DebugConsoleIconActionButton(
            icon: Icons.delete_outline,
            tooltip: '현재 목록 초기화',
            onPressed: () async => onClear(),
          ),
        ],
      ),
    );
  }
}
