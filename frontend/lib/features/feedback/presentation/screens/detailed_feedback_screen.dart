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
import 'package:teeq/features/feedback/domain/detailed_feedback_answers.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_character_name_builder.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_reason_input_field.dart';
import 'package:teeq/features/feedback/presentation/widgets/memory_not_applicable_check_row.dart';
import 'package:teeq/features/feedback/presentation/widgets/required_feedback_question.dart';
import 'package:teeq/features/feedback/presentation/widgets/scaled_question_section.dart';
import 'package:teeq/features/feedback/presentation/widgets/start_reason_checklist.dart';

/// 상세 피드백 8문항 화면. `<`와 시스템 뒤로 가기는 확인창 없이 응답을 버리고 홈으로 나간다.
class DetailedFeedbackScreen extends ConsumerWidget {
  const DetailedFeedbackScreen({super.key, required this.callSessionId});

  final String callSessionId;

  static const List<String> _agreementAnchorLabels = [
    '전혀 아니야',
    '보통이야',
    '정말 그랬어',
  ];

  /// 홈으로 나가며 응답을 비운다. 이동을 먼저 해야 남아 있는 화면이 빈 상태로 다시 그려지지 않는다.
  void _exitToHome(BuildContext context, WidgetRef ref) {
    context.go(AppRoutes.home);
    ref.read(feedbackFlowControllerProvider.notifier).reset();
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(feedbackFlowControllerProvider.notifier)
        .submitDetailed();
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case DetailedFeedbackSubmitResult.submitted:
        context.go(AppRoutes.detailedFeedbackCompletionLocation(callSessionId));
      case DetailedFeedbackSubmitResult.alreadySubmitted:
        _exitToHome(context, ref);
      case DetailedFeedbackSubmitResult.failed:
      case DetailedFeedbackSubmitResult.ignored:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackFlowControllerProvider);
    final controller = ref.read(feedbackFlowControllerProvider.notifier);
    final answers = state.detailedAnswers;
    // 제출이 끝난 뒤 화면이 바뀌는 동안 같은 응답이 다시 나가지 않게 막는다.
    final canSubmit =
        answers.isComplete &&
        !state.isRequestInProgress &&
        !state.detailedSubmitted;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitToHome(context, ref);
        }
      },
      child: FeedbackCharacterNameBuilder(
        builder: (context, characterName) => BottomActionScreenLayout(
          onBackPressed: () => _exitToHome(context, ref),
          bottomAction: PrimaryFilledButton(
            label: '의견 보내기',
            onPressed: canSubmit
                ? () => unawaited(_submit(context, ref))
                : null,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.space28,
            children: [
              _Header(characterName: characterName),
              ..._questions(characterName, answers, controller),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _questions(
    String characterName,
    DetailedFeedbackAnswers answers,
    FeedbackFlowController controller,
  ) {
    Widget scaled({
      required DetailedFeedbackQuestion question,
      required String title,
      required List<String> anchorLabels,
      required String reasonExample,
      Widget? footer,
    }) {
      return ScaledQuestionSection(
        title: title,
        anchorLabels: anchorLabels,
        score: answers.scores[question],
        onScoreChanged: (score) => controller.setDetailedScore(question, score),
        reasonText: answers.reasons[question] ?? '',
        onReasonChanged: (reason) =>
            controller.setDetailedReason(question, reason),
        reasonExample: reasonExample,
        isScoreEnabled:
            question != DetailedFeedbackQuestion.memory ||
            answers.isMemoryScoreRequired,
        footer: footer,
      );
    }

    return [
      scaled(
        question: DetailedFeedbackQuestion.timing,
        title:
            '1. ${withConjunctiveParticle(characterName)} '
            '말 주고받는 타이밍은 자연스러웠어?',
        anchorLabels: const ['너무 어색했어', '보통이야', '정말 자연스러웠어'],
        reasonExample: '예) 끼어들지 않고 잘 들어줘서 편했어.',
      ),
      scaled(
        question: DetailedFeedbackQuestion.personaFit,
        title: '2. 내가 설정한 $characterName의 성격과 말투가 잘 느껴졌어?',
        anchorLabels: _agreementAnchorLabels,
        reasonExample: '예) 다정하고 활발한 느낌이 대화 내내 유지됐어.',
      ),
      scaled(
        question: DetailedFeedbackQuestion.memory,
        title:
            '3. ${withSubjectParticle(characterName)} '
            '우리 대화를 잘 기억하고 이어갔어?',
        anchorLabels: _agreementAnchorLabels,
        reasonExample: '예) 지난번에 했던 고민을 먼저 물어봐서 좋았어.',
        footer: MemoryNotApplicableCheckRow(
          isChecked: answers.memoryNotApplicable,
          onChanged: controller.setMemoryNotApplicable,
        ),
      ),
      scaled(
        question: DetailedFeedbackQuestion.empathyTrust,
        title: '4. $characterName의 대답은 공감되고 믿음이 갔어?',
        anchorLabels: _agreementAnchorLabels,
        reasonExample: '예) 현실적인 조언이라 도움이 됐어.',
      ),
      RequiredFeedbackQuestion(
        title: '5. 가장 좋았거나 아쉬웠던 순간이 있었어?',
        helperText: '선택',
        child: FeedbackReasonInputField(
          title: '기억나는 순간이나 더 바라는 점을 자유롭게 알려줘.',
          text: answers.freeText,
          onChanged: controller.setFreeText,
          maxLength: FeedbackInputLimits.freeTextMaxLength,
        ),
      ),
      scaled(
        question: DetailedFeedbackQuestion.personalComfort,
        title: '6. $characterName에게 개인적인 이야기를 해도 괜찮겠다고 느꼈어?',
        anchorLabels: _agreementAnchorLabels,
        reasonExample: '그렇게 느낀 이유를 편하게 알려줘.',
      ),
      scaled(
        question: DetailedFeedbackQuestion.storageComfort,
        title: '7. 대화가 기억·저장되는 게 불안하지 않았어?',
        anchorLabels: const ['매우 불안했어', '보통이야', '전혀 불안하지 않았어'],
        reasonExample: '기억·저장과 관련해 어떤 점이 편하거나 불안했어?',
      ),
      RequiredFeedbackQuestion(
        title: '8. 오늘 통화를 시작한 이유는 뭐야?',
        helperText: '해당하는 이유를 모두 골라줘.',
        child: StartReasonChecklist(
          characterName: characterName,
          selected: answers.startReasons,
          onToggle: controller.toggleStartReason,
          otherText: answers.startReasonOtherText,
          onOtherTextChanged: controller.setStartReasonOtherText,
        ),
      ),
    ];
  }
}

/// 제목과 부제, 그리고 이미지 없이 크기만 잡아 둔 오른쪽 마스코트 자리.
class _Header extends StatelessWidget {
  const _Header({required this.characterName});

  final String characterName;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppLayout.detailedFeedbackHeaderMinHeight,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.detailedFeedbackHeaderTextMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.space8,
              children: [
                Text(
                  '${withConjunctiveParticle(characterName)}의 대화,\n'
                  '조금 더 알려줄래?',
                  style: AppTextStyles.title24Bold,
                ),
                Text(
                  '기억나는 부분만 편하게 알려줘!',
                  style: AppTextStyles.body14RegularMultiline.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: -AppLayout.horizontalMargin,
            top: -AppLayout.detailedFeedbackMascotSlotOverhang,
            child: SizedBox(
              width: AppLayout.detailedFeedbackMascotSlotWidth,
              height: AppLayout.detailedFeedbackMascotSlotHeight,
            ),
          ),
        ],
      ),
    );
  }
}
