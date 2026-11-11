import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';

/// 통화를 시작하기 전에 안내 모달을 띄운다. "통화 시작" 버튼으로만 닫히고, 닫히면 반환한 Future가 끝난다.
Future<void> showCallGuideDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrimSoft,
    builder: (_) => const CallGuideDialog(),
  );
}

/// 통화 전 안내 모달. 바깥 탭과 뒤로가기는 막고 "통화 시작" 버튼만 모달을 닫는다.
class CallGuideDialog extends StatefulWidget {
  const CallGuideDialog({super.key});

  @override
  State<CallGuideDialog> createState() => _CallGuideDialogState();
}

class _CallGuideDialogState extends State<CallGuideDialog> {
  static const String _title = '통화 전에 잠깐!';
  static const String _description =
      '주변이 조용할수록 네 목소리가 더 또렷하게 전해져!\n'
      '또, 블루투스 기기를 쓰면 통화 소리가\n'
      '조금 덜 선명하게 들릴 수 있어.';
  static const String _startButtonLabel = '통화 시작';

  /// 닫힘 애니메이션 중 들어오는 연속 입력이 `pop`을 두 번 불러 아래 화면까지 닫지 않게 막는다.
  bool _isClosing = false;

  void _close() {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppLayout.horizontalMargin,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space40,
            AppSpacing.space20,
            AppSpacing.space20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title24Bold,
              ),
              const SizedBox(height: AppSpacing.space40),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: AppTextStyles.body14RegularMultiline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space32),
              PrimaryFilledButton(label: _startButtonLabel, onPressed: _close),
            ],
          ),
        ),
      ),
    );
  }
}
