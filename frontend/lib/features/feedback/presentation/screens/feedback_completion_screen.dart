import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/sheets/detailed_feedback_invitation_sheet.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_character_name_builder.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_response_summary_card.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

/// 필수 피드백을 보낸 뒤의 완료 화면. 상세 피드백에 초대받았으면 한 번만 초대 시트를 띄운다.
/// 뒤로 가기는 막고 "홈으로 가기"로만 나간다.
class FeedbackCompletionScreen extends ConsumerStatefulWidget {
  const FeedbackCompletionScreen({super.key, required this.callSessionId});

  final String callSessionId;

  @override
  ConsumerState<FeedbackCompletionScreen> createState() =>
      _FeedbackCompletionScreenState();
}

class _FeedbackCompletionScreenState
    extends ConsumerState<FeedbackCompletionScreen> {
  bool _hasShownInvitation = false;

  @override
  void initState() {
    super.initState();
    // 홈 요약은 autoDispose라 이 화면에서 다시 조회되며 캐릭터 이름은 나중에 도착한다.
    // 요약이 처음 도착했을 때(이미 값이 있으면 곧바로) 초대 시트를 한 번만 띄운다.
    final memberId = ref.read(currentMemberControllerProvider)?.memberId;
    if (memberId != null) {
      ref.listenManual(
        homeSummaryProvider(memberId),
        (previous, next) => _showInvitationOnce(next.value),
        fireImmediately: true,
      );
    }
  }

  void _showInvitationOnce(HomeSummary? summary) {
    if (summary == null || _hasShownInvitation) {
      return;
    }
    final flowState = ref.read(feedbackFlowControllerProvider);
    final callIndex = flowState.status?.callIndex;
    if (!flowState.detailedFeedbackInvited || callIndex == null) {
      return;
    }
    _hasShownInvitation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_showInvitation(summary.characterName, callIndex));
    });
  }

  Future<void> _showInvitation(String characterName, int callIndex) async {
    final choice = await showDetailedFeedbackInvitationSheet(
      context,
      characterName: characterName,
      callIndex: callIndex,
    );
    if (!mounted) {
      return;
    }
    // 시트를 그냥 닫은 경우(null)도 거절로 본다.
    if (choice == DetailedFeedbackInvitationChoice.accept) {
      context.go(AppRoutes.detailedFeedbackLocation(widget.callSessionId));
    } else {
      _exitToHome();
    }
  }

  /// 홈으로 나가며 흐름 상태를 비운다. 이동을 먼저 해야 남아 있는 화면이 빈 상태로 다시 그려지지 않는다.
  void _exitToHome() {
    context.go(AppRoutes.home);
    ref.read(feedbackFlowControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(feedbackFlowControllerProvider);
    final answers = flowState.requiredAnswers;
    final rating = answers.rating;
    final revisitIntention = answers.revisitIntention;
    return PopScope(
      canPop: false,
      child: FeedbackCharacterNameBuilder(
        builder: (context, characterName) => BottomActionScreenLayout(
          bottomAction: PrimaryFilledButton(
            label: '홈으로 가기',
            onPressed: _exitToHome,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppLayout.completionMascotTopOffset),
              const Center(
                child: TeeqMascot(
                  pose: TeeqMascotPose.excited,
                  width: AppLayout.completionMascotSize,
                ),
              ),
              const Text(
                '피드백을\n보내줬어!',
                textAlign: TextAlign.center,
                style: AppTextStyles.display32Bold,
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                '소중한 의견 덕분에\n'
                '${withSubjectParticle(characterName)} 조금 더 성장할 수 있을 거야.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body16RegularMultiline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              if (rating != null && revisitIntention != null)
                FeedbackResponseSummaryCard(
                  rating: rating,
                  revisitIntention: revisitIntention,
                  previousCallRecall:
                      flowState.status?.previousCallRecallRequired == true
                      ? answers.previousCallRecall
                      : null,
                  awkwardMoments: answers.awkwardMoments,
                ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
