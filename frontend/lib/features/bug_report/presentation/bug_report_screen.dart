import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/bug_report/domain/bug_report_source.dart';
import 'package:teeq/features/bug_report/presentation/bug_report_submission_controller.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_content_field.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_image_attachment_field.dart';
import 'package:teeq/features/my_page/presentation/widgets/back_button_with_centered_title_header.dart';

/// 마이 화면의 "버그 제보"로 들어오는 일반 제보 화면. 로그는 싣지 않는다.
class BugReportScreen extends ConsumerStatefulWidget {
  const BugReportScreen({super.key});

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
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
          source: BugReportSource.user,
          content: _contentController.text,
          imagePaths: _imagePaths,
        );
    if (!isSubmitted) {
      return;
    }
    toast.show('제보가 접수되었어요');
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(bugReportSubmissionControllerProvider)
        .isLoading;
    final canSubmit = _contentController.text.trim().isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackButtonWithCenteredTitleHeader(
              title: '버그 제보',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.horizontalMargin,
                  AppSpacing.space20,
                  AppLayout.horizontalMargin,
                  AppSpacing.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BugReportContentField(
                      controller: _contentController,
                      isEnabled: !isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      '어떤 상황에서 문제가 생겼는지 적어 주세요',
                      style: AppTextStyles.caption12Medium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    BugReportImageAttachmentField(
                      imagePaths: _imagePaths,
                      isEnabled: !isSubmitting,
                      onChanged: (paths) => setState(() => _imagePaths = paths),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.horizontalMargin,
                0,
                AppLayout.horizontalMargin,
                AppSpacing.space12,
              ),
              child: PrimaryFilledButton(
                label: '제보하기',
                onPressed: canSubmit ? _submit : null,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
