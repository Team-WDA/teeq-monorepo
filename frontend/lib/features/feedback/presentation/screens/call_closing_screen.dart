import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/sheets/required_feedback_sheet.dart';
import 'package:teeq/features/feedback/presentation/widgets/closing_mascot_with_glow.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_character_name_builder.dart';

/// 통화가 끝난 직후의 마무리 화면. 들어올 때마다 피드백 흐름을 새로 시작한다.
/// 뒤로 가기는 막고, "의견 남기기"를 누르면 필수 피드백 시트를 연다.
class CallClosingScreen extends ConsumerStatefulWidget {
  const CallClosingScreen({super.key, required this.callSessionId});

  final String callSessionId;

  @override
  ConsumerState<CallClosingScreen> createState() => _CallClosingScreenState();
}

class _CallClosingScreenState extends ConsumerState<CallClosingScreen> {
  @override
  void initState() {
    super.initState();
    // 빌드 중에 Notifier 상태를 바꾸면 Riverpod이 예외를 던지므로 첫 프레임 뒤에 시작한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(feedbackFlowControllerProvider.notifier)
          .start(widget.callSessionId);
    });
  }

  /// 상태를 조회한 뒤 필수 시트를 열고, 시트 결과에 따라 이동한다.
  /// 조회가 일시적으로 실패하면 이 화면에 머물러 버튼으로 다시 시도할 수 있고,
  /// 통화 세션이 없으면 다시 시도해도 소용없으므로 홈으로 나간다.
  Future<void> _openRequiredFeedback(String characterName) async {
    final loadResult = await ref
        .read(feedbackFlowControllerProvider.notifier)
        .loadStatus();
    if (!mounted || loadResult == FeedbackStatusLoadResult.failed) {
      return;
    }
    switch (loadResult) {
      case FeedbackStatusLoadResult.alreadySubmitted:
      case FeedbackStatusLoadResult.unavailable:
        _exitToHome();
      case FeedbackStatusLoadResult.ready:
        await _showRequiredSheet(characterName);
      case FeedbackStatusLoadResult.failed:
      case FeedbackStatusLoadResult.ignored:
        return;
    }
  }

  /// 홈으로 나가며 흐름 상태를 비운다. 이동을 먼저 해야 남아 있는 화면이 빈 상태로 다시 그려지지 않는다.
  void _exitToHome() {
    context.go(AppRoutes.home);
    ref.read(feedbackFlowControllerProvider.notifier).reset();
  }

  Future<void> _showRequiredSheet(String characterName) async {
    final status = ref.read(feedbackFlowControllerProvider).status;
    if (status == null) {
      return;
    }
    final result = await showRequiredFeedbackSheet(
      context,
      characterName: characterName,
      previousCallRecallRequired: status.previousCallRecallRequired,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case RequiredFeedbackSubmitResult.submitted:
      case RequiredFeedbackSubmitResult.submittedWithInvitation:
        context.go(AppRoutes.feedbackCompletionLocation(widget.callSessionId));
      case RequiredFeedbackSubmitResult.alreadySubmitted:
        _exitToHome();
      case RequiredFeedbackSubmitResult.failed:
      case RequiredFeedbackSubmitResult.ignored:
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequestInProgress = ref.watch(
      feedbackFlowControllerProvider.select(
        (state) => state.isRequestInProgress,
      ),
    );
    return PopScope(
      canPop: false,
      child: FeedbackCharacterNameBuilder(
        builder: (context, characterName) => BottomActionScreenLayout(
          bottomAction: PrimaryFilledButton(
            label: '의견 남기기',
            // 조회 중에는 비활성으로 두어 같은 요청이 겹치지 않게 한다.
            onPressed: isRequestInProgress
                ? null
                : () => unawaited(_openRequiredFeedback(characterName)),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppLayout.closingMascotTopOffset),
              const ClosingMascotWithGlow(),
              const SizedBox(height: AppLayout.closingMascotToTitleGap),
              const Text(
                '이야기해서 좋았어!',
                textAlign: TextAlign.center,
                style: AppTextStyles.title24Bold,
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                '${withTogetherParticle(characterName)} 통화한 거 어땠어?\n'
                '짧게 의견을 남겨주면\n'
                '다음엔 더 좋은 대화를 나눌 수 있어!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body14SemiBoldMultiline.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
