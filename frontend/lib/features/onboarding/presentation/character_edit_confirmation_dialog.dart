import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';
import 'package:teeq/core/ui/button/rounded_pill_button.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_character_illustration.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_catalog_provider.dart';

/// 캐릭터 성향을 다시 설정할지 묻는 팝업을 띄운다. 이름은 호출하는 홈이 넘긴다.
Future<void> showCharacterEditConfirmationDialog(
  BuildContext context, {
  required String characterName,
  required CharacterType characterType,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => CharacterEditConfirmationDialog(
      characterName: characterName,
      characterType: characterType,
    ),
  );
}

/// 캐릭터 수정 확인 팝업. 닫기·취소는 팝업만 닫고 "다시 설정하기"는 질문 카탈로그를 불러온 뒤
/// 수정 흐름을 시작한다.
class CharacterEditConfirmationDialog extends ConsumerStatefulWidget {
  const CharacterEditConfirmationDialog({
    super.key,
    required this.characterName,
    required this.characterType,
  });

  final String characterName;
  final CharacterType characterType;

  @override
  ConsumerState<CharacterEditConfirmationDialog> createState() =>
      _CharacterEditConfirmationDialogState();
}

class _CharacterEditConfirmationDialogState
    extends ConsumerState<CharacterEditConfirmationDialog> {
  bool _isLoadingCatalog = false;

  static const CharacterMood _characterMood = CharacterMood.curious;

  /// 바닥 기준선을 상자 위쪽 기준 [AppLayout.dialogCharacterBaselineY]에 맞추는 이미지 중심의 세로 이동량(상자 중심 기준).
  static const double _centerOffsetY =
      AppLayout.dialogCharacterBaselineY -
      AppLayout.characterGroundFraction * AppLayout.dialogIllustrationSize +
      AppLayout.dialogIllustrationSize / 2 -
      AppLayout.dialogIllustrationHeight / 2;

  @override
  Widget build(BuildContext context) {
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
                      child: SizedBox(
                        width: AppLayout.dialogIllustrationWidth * scale,
                        height: AppLayout.dialogIllustrationHeight * scale,
                        child: OffsetCharacterIllustration(
                          characterType: widget.characterType,
                          characterMood: _characterMood,
                          size: AppLayout.dialogIllustrationSize * scale,
                          offset: Offset(0, _centerOffsetY * scale),
                        ),
                      ),
                    ),
                  ),
                ),
                const AccentOutlineHintTag(message: '걱정 마! 우리의 기억은 그대로야.'),
                const SizedBox(height: AppSpacing.space32),
                Text(
                  '${widget.characterName}의 성향을 다시 설정할까?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading20Bold,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  '처음 만날 때와 같은 질문이 다시 나타나요.\n'
                  '새로운 답변에 맞춰 ${widget.characterName}의 성향과\n'
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
                        isLoading: _isLoadingCatalog,
                        onPressed: _startEditFlow,
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

  Future<void> _startEditFlow() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isLoadingCatalog) {
      return;
    }
    setState(() => _isLoadingCatalog = true);
    final errorHandler = ref.read(errorHandlerProvider);
    final flowController = ref.read(
      characterSetupFlowControllerProvider.notifier,
    );
    // 이전 진입에서 화면이 먼저 사라져 비우지 못한 실패 결과가 남아 있으면 새로 불러오게 한다.
    // 다시 불러오는 중인 상태도 이전 오류를 들고 있으므로 끝난 오류일 때만 비운다.
    final cachedCatalog = ref.read(onboardingCatalogProvider);
    if (cachedCatalog.hasError && !cachedCatalog.isLoading) {
      ref.invalidate(onboardingCatalogProvider);
    }
    try {
      await ref.read(onboardingCatalogProvider.future);
    } on Object catch (error) {
      // 팝업은 닫지 않고 버튼으로 다시 시도하게 한다.
      errorHandler.handle(error);
      if (mounted) {
        // 실패한 결과가 캐시되므로 비워서 다음 탭에 다시 불러오게 한다.
        ref.invalidate(onboardingCatalogProvider);
        setState(() => _isLoadingCatalog = false);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    // 다이얼로그가 닫히면 context를 쓸 수 없으므로 먼저 라우터를 잡는다.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    flowController.start(CharacterSetupMode.edit);
    router.go(AppRoutes.onboardingQuestions);
  }
}
