import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';
import 'package:teeq/core/ui/button/rounded_pill_button.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';

/// 캐릭터 성향을 다시 설정할지 묻는 팝업을 띄운다. 이름은 호출하는 홈이 넘긴다.
Future<void> showCharacterEditConfirmationDialog(
  BuildContext context, {
  required String characterName,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) =>
        CharacterEditConfirmationDialog(characterName: characterName),
  );
}

/// 캐릭터 수정 확인 팝업. 닫기·취소는 팝업만 닫고 "다시 설정하기"는 수정 흐름을 시작한다.
class CharacterEditConfirmationDialog extends ConsumerWidget {
  const CharacterEditConfirmationDialog({
    super.key,
    required this.characterName,
  });

  final String characterName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppLayout.dialogHorizontalInset,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.horizontalMargin,
              AppSpacing.space8,
              AppLayout.horizontalMargin,
              AppSpacing.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DesignFrameScaleBuilder(
                    designWidth: AppLayout.dialogContentWidth,
                    builder: (context, scale) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Image.asset(
                        AppAssets.characterEditPrompt,
                        width: AppLayout.dialogIllustrationWidth * scale,
                        height: AppLayout.dialogIllustrationHeight * scale,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const AccentOutlineHintTag(message: '걱정 마! 우리의 기억은 그대로야.'),
                const SizedBox(height: AppSpacing.space32),
                Text(
                  '$characterName의 성향을 다시 설정할까?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading20Bold,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  '처음 만날 때와 같은 질문이 다시 나타나요.\n'
                  '새로운 답변에 맞춰 $characterName의 성향과\n'
                  '대화 스타일이 달라져요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption12SemiBoldMultiline.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.space32),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: RoundedPillButton(
                        label: '취소',
                        style: RoundedPillButtonStyle.outlined,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      flex: 5,
                      child: RoundedPillButton(
                        label: '다시 설정하기',
                        onPressed: () => _startEditFlow(context, ref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.space4,
            right: AppSpacing.space4,
            child: AppCloseButton(onPressed: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }

  void _startEditFlow(BuildContext context, WidgetRef ref) {
    // 다이얼로그가 닫히면 context를 쓸 수 없으므로 먼저 라우터와 컨트롤러를 잡는다.
    final router = GoRouter.of(context);
    final flowController = ref.read(
      characterSetupFlowControllerProvider.notifier,
    );
    Navigator.of(context).pop();
    flowController.start(CharacterSetupMode.edit);
    router.go(AppRoutes.onboardingQuestions);
  }
}
