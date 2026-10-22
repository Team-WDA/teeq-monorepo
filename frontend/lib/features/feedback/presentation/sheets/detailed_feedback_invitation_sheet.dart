import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/core/ui/bottom_sheet/app_bottom_sheet.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/feedback/presentation/widgets/invitation_sheet_decoration.dart';

/// 상세 피드백 초대에 대한 사용자의 선택.
enum DetailedFeedbackInvitationChoice { accept, decline }

/// 상세 피드백 초대 시트를 띄운다. 스크림 탭·스와이프·뒤로 가기로도 닫히며 이때 결과는 null(거절로 본다)이다.
/// [callIndex]는 이번 통화가 몇 번째 통화인지 나타낸다.
Future<DetailedFeedbackInvitationChoice?> showDetailedFeedbackInvitationSheet(
  BuildContext context, {
  required String characterName,
  required int callIndex,
}) {
  return showAppBottomSheet<DetailedFeedbackInvitationChoice>(
    context: context,
    builder: (sheetContext) => _DetailedFeedbackInvitationSheetContent(
      characterName: characterName,
      callIndex: callIndex,
    ),
  );
}

class _DetailedFeedbackInvitationSheetContent extends StatelessWidget {
  const _DetailedFeedbackInvitationSheetContent({
    required this.characterName,
    required this.callIndex,
  });

  final String characterName;
  final int callIndex;

  /// 닫히는 중인 시트에서 한 번 더 눌려도 아래 화면까지 닫히지 않게 현재 경로일 때만 닫는다.
  void _close(BuildContext context, DetailedFeedbackInvitationChoice choice) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return;
    }
    Navigator.pop(context, choice);
  }

  @override
  Widget build(BuildContext context) {
    final nameWithConjunctiveParticle = withConjunctiveParticle(characterName);
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.invitationSheetHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppLayout.invitationSheetTopInset),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.invitationSheetHorizontalInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.space12,
                children: [
                  Text(
                    '$nameWithConjunctiveParticle의 대화,\n조금 더 알려줄래?',
                    style: AppTextStyles.title28Bold,
                  ),
                  Text(
                    '벌써 $nameWithConjunctiveParticle $callIndex번째 대화를 나눴네!\n'
                    '조금 더 자세히 알려주면,\n'
                    '앞으로의 대화가 더 좋아질 수 있어.',
                    style: AppTextStyles.body16RegularMultiline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalMargin,
              ),
              child: InvitationSheetDecoration(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalMargin,
              ),
              child: PrimaryFilledButton(
                label: '자세히 알려주기',
                onPressed: () =>
                    _close(context, DetailedFeedbackInvitationChoice.accept),
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            Semantics(
              button: true,
              excludeSemantics: true,
              label: '다음에 할게',
              onTap: () =>
                  _close(context, DetailedFeedbackInvitationChoice.decline),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _close(context, DetailedFeedbackInvitationChoice.decline),
                child: const SizedBox(
                  height: AppLayout.textButtonHeight,
                  child: Center(
                    child: Text('다음에 할게', style: AppTextStyles.body14Medium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space14),
          ],
        ),
      ),
    );
  }
}
