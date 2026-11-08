import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';

/// 통화를 시작하기 전에 안내 모달을 띄운다. X 버튼으로만 닫히고, 닫히면 반환한 Future가 끝난다.
Future<void> showCallGuideDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrimSoft,
    builder: (_) => const CallGuideDialog(),
  );
}

/// 통화 전 안내 모달. 바깥 탭과 뒤로가기는 막고 X 버튼만 모달을 닫는다.
class CallGuideDialog extends StatelessWidget {
  const CallGuideDialog({super.key});

  static const String _title = '통화 전에 잠깐!';
  static const String _description =
      '주변이 조용할수록 네 목소리가 더 또렷하게 전해져!\n'
      '또, 블루투스 기기를 쓰면 통화 소리가\n'
      '조금 덜 선명하게 들릴 수 있어.';

  /// 닫기 아이콘(24)을 시안 위치(위 24, 오른쪽 20)에 맞추려고 탭 영역(48)을 절반만큼 바깥으로 민다.
  static const double _closeButtonTop =
      AppSpacing.space24 -
      (AppLayout.minimumTapTarget - AppLayout.dialogCloseIconSize) / 2;
  static const double _closeButtonRight =
      AppSpacing.space20 -
      (AppLayout.minimumTapTarget - AppLayout.dialogCloseIconSize) / 2;

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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space20,
                AppSpacing.space24,
                AppSpacing.space20,
                AppSpacing.space32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppLayout.dialogCloseIconSize),
                  const SizedBox(height: AppSpacing.space40),
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
                ],
              ),
            ),
            Positioned(
              top: _closeButtonTop,
              right: _closeButtonRight,
              child: AppCloseButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
