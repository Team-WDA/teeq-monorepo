import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/call/presentation/widgets/call_card_primary_button.dart';
import 'package:teeq/features/call/presentation/widgets/call_card_secondary_button.dart';

/// 통화 화면 위에 띄우는 안내 카드(권한 필요, 연결 실패, 곧 종료, 한도 소진, 종료 확인 등).
/// 제목·본문·선택 칩·주 버튼·보조 버튼을 위에서 아래로 쌓는다. 부모 폭을 모두 채운다.
/// [body]가 없으면(종료 확인 카드) 시안대로 제목을 가운데 정렬하고 간격을 줄인다.
/// 보조 버튼은 [secondaryLabel]과 [onSecondaryPressed]를 함께 주거나 함께 비운다(통화 시작 전 한도 화면은 버튼 하나).
class CallStatusCard extends StatelessWidget {
  const CallStatusCard({
    super.key,
    required this.title,
    this.body,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.infoChip,
  }) : assert(
         (secondaryLabel == null) == (onSecondaryPressed == null),
         '보조 버튼 문구와 콜백은 함께 주거나 함께 비워야 한다.',
       );

  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? infoChip;

  @override
  Widget build(BuildContext context) {
    final bodyText = body;
    final itemGap = bodyText == null ? AppSpacing.space12 : AppSpacing.space16;
    final chip = infoChip;
    final secondaryButtonLabel = secondaryLabel;
    final secondaryButtonCallback = onSecondaryPressed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space20,
        vertical: AppSpacing.space24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: itemGap,
        children: [
          Text(
            title,
            textAlign: bodyText == null ? TextAlign.center : TextAlign.start,
            style: AppTextStyles.title24Bold,
          ),
          if (bodyText != null)
            Text(
              bodyText,
              style: AppTextStyles.body14RegularMultiline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ?chip,
          CallCardPrimaryButton(
            label: primaryLabel,
            onPressed: onPrimaryPressed,
          ),
          if (secondaryButtonLabel != null && secondaryButtonCallback != null)
            CallCardSecondaryButton(
              label: secondaryButtonLabel,
              onPressed: secondaryButtonCallback,
            ),
        ],
      ),
    );
  }
}
