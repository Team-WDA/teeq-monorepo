import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/debug_console/bug_report_log_snapshot_builder.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_icon_action_button.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/presentation/bug_report_submission_controller.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_content_field.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_image_attachment_field.dart';

/// 개발자 콘솔 안에서 열리는 제보 시트. 콘솔은 Navigator 위에 있어 라우트 시트를 쓸 수 없으므로
/// 패널 안에 직접 겹쳐 그린다. 제출하면 현재 콘솔 로그를 함께 보낸다.
class DebugConsoleBugReportSheet extends ConsumerStatefulWidget {
  const DebugConsoleBugReportSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<DebugConsoleBugReportSheet> createState() =>
      _DebugConsoleBugReportSheetState();
}

class _DebugConsoleBugReportSheetState
    extends ConsumerState<DebugConsoleBugReportSheet> {
  final TextEditingController _contentController = TextEditingController();
  List<String> _imagePaths = const [];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _submit() async {
    final toast = ref.read(toastControllerProvider.notifier);
    final isSubmitted = await ref
        .read(bugReportSubmissionControllerProvider.notifier)
        .submit(
          source: BugReportSource.developerConsole,
          content: _contentController.text,
          imagePaths: _imagePaths,
          logSnapshot: buildBugReportLogSnapshot(
            ref.read(debugConsoleStoreProvider),
          ),
        );
    if (!isSubmitted) {
      return;
    }
    toast.show('제보가 접수되었어요');
    if (mounted) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(bugReportSubmissionControllerProvider)
        .isLoading;
    final canSubmit =
        !isSubmitting && _contentController.text.trim().isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isSubmitting ? null : widget.onClose,
            child: const ColoredBox(color: AppColors.scrimSoft),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.space16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '버그 제보',
                            style: AppTextStyles.heading20Bold,
                          ),
                        ),
                        DebugConsoleIconActionButton(
                          icon: Icons.close,
                          tooltip: '제보 닫기',
                          onPressed: () async {
                            if (!isSubmitting) {
                              widget.onClose();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BugReportContentField(
                            controller: _contentController,
                            isEnabled: !isSubmitting,
                          ),
                          const SizedBox(height: AppSpacing.space16),
                          BugReportImageAttachmentField(
                            imagePaths: _imagePaths,
                            isEnabled: !isSubmitting,
                            onChanged: (paths) =>
                                setState(() => _imagePaths = paths),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    child: PrimaryFilledButton(
                      label: '제보하기',
                      onPressed: canSubmit ? _submit : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
