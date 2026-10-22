import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/neutral_filled_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

/// 회원 탈퇴 확인 모달을 띄운다.
Future<void> showAccountWithdrawalConfirmationDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrimSoft,
    builder: (_) => const AccountWithdrawalConfirmationDialog(),
  );
}

/// 회원 탈퇴 확인 모달. "계속 이용하기"와 스크림은 모달만 닫고, "탈퇴하기"는 계정을 삭제한다.
/// 요청 중에는 두 버튼과 스크림 닫기를 막고, 실패하면 모달을 유지한다.
class AccountWithdrawalConfirmationDialog extends ConsumerStatefulWidget {
  const AccountWithdrawalConfirmationDialog({super.key});

  @override
  ConsumerState<AccountWithdrawalConfirmationDialog> createState() =>
      _AccountWithdrawalConfirmationDialogState();
}

class _AccountWithdrawalConfirmationDialogState
    extends ConsumerState<AccountWithdrawalConfirmationDialog> {
  bool _isRequestInProgress = false;

  Future<void> _withdraw() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isRequestInProgress) {
      return;
    }
    setState(() => _isRequestInProgress = true);
    // 모달이 먼저 닫혀도 쓸 수 있게 await 전에 가져온다.
    final navigator = Navigator.of(context);
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      // 세션이 지워져 환영 화면으로 바뀌기 전에 모달을 먼저 닫는다.
      await authFlow.deleteAccount(beforeSigningOut: navigator.pop);
    } on Object catch (error) {
      errorHandler.handle(error);
      if (mounted) {
        setState(() => _isRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isRequestInProgress,
      child: Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppLayout.horizontalMargin,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('정말 탈퇴할까?', style: AppTextStyles.title24Bold),
              const SizedBox(height: AppSpacing.space16),
              Text(
                '탈퇴하면 이 계정으로\n'
                'TeeQ를 이용할 수 없어.\n'
                '계속하려면 아래에서 탈퇴를 선택해줘.',
                style: AppTextStyles.body14MediumMultiline,
              ),
              const SizedBox(height: AppSpacing.space16),
              NeutralFilledButton(
                label: '계속 이용하기',
                onPressed: _isRequestInProgress
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.space16),
              PrimaryFilledButton(
                label: '탈퇴하기',
                onPressed: _isRequestInProgress ? null : _withdraw,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
