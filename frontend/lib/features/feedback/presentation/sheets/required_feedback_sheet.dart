import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/core/ui/bottom_sheet/app_bottom_sheet.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_group.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_option_labels.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_rating.dart';
import 'package:teeq/features/feedback/presentation/widgets/required_feedback_question.dart';
import 'package:teeq/features/feedback/presentation/widgets/required_feedback_sheet_header.dart';

/// 필수 피드백 시트를 띄운다. 스크림 탭·스와이프·뒤로 가기로 닫을 수 없고,
/// 제출에 성공하거나 이미 제출된 통화이면 그 결과를 돌려주며 닫힌다.
/// 제출이 실패하거나 무시되면 시트를 유지한다.
Future<RequiredFeedbackSubmitResult?> showRequiredFeedbackSheet(
  BuildContext context, {
  required String characterName,
  required bool previousCallRecallRequired,
}) {
  // 시트 껍데기 안쪽에서는 하단 안전 영역이 이미 소비되므로 호출한 화면에서 미리 읽는다.
  final bottomSafeAreaInset = MediaQuery.paddingOf(context).bottom;
  return showAppBottomSheet<RequiredFeedbackSubmitResult>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _RequiredFeedbackSheetContent(
      characterName: characterName,
      previousCallRecallRequired: previousCallRecallRequired,
      bottomSafeAreaInset: bottomSafeAreaInset,
    ),
  );
}

class _RequiredFeedbackSheetContent extends ConsumerWidget {
  const _RequiredFeedbackSheetContent({
    required this.characterName,
    required this.previousCallRecallRequired,
    required this.bottomSafeAreaInset,
  });

  final String characterName;
  final bool previousCallRecallRequired;

  /// 시트 껍데기가 하단에 더하는 안전 영역 높이.
  final double bottomSafeAreaInset;

  static const int _choiceColumnCount = 3;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(feedbackFlowControllerProvider.notifier)
        .submitRequired();
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case RequiredFeedbackSubmitResult.submitted:
      case RequiredFeedbackSubmitResult.submittedWithInvitation:
      case RequiredFeedbackSubmitResult.alreadySubmitted:
        Navigator.pop(context, result);
      case RequiredFeedbackSubmitResult.failed:
      case RequiredFeedbackSubmitResult.ignored:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackFlowControllerProvider);
    final controller = ref.read(feedbackFlowControllerProvider.notifier);
    final answers = state.requiredAnswers;
    // 제출이 끝난 뒤 시트가 닫히는 동안 같은 응답이 다시 나가지 않게 막는다.
    final canSubmit =
        answers.isComplete(
          previousCallRecallRequired: previousCallRecallRequired,
        ) &&
        !state.isRequestInProgress &&
        !state.requiredSubmitted;
    // 문항 번호는 보이는 순서대로 붙는다.
    var questionNumber = 1;
    String numbered(String title) => '${questionNumber++}. $title';
    const horizontalMargin = AppLayout.horizontalMargin;
    return SizedBox(
      // 껍데기가 하단 안전 영역을 더하므로 그만큼 빼야 시트 윗선이 고정 위치에 놓인다.
      height:
          MediaQuery.sizeOf(context).height -
          AppLayout.requiredSheetTopOffset -
          bottomSafeAreaInset,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                horizontalMargin,
                AppLayout.requiredSheetContentTopInset,
                horizontalMargin,
                AppSpacing.space20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.space20,
                children: [
                  const RequiredFeedbackSheetHeader(),
                  RequiredFeedbackQuestion(
                    title: numbered('오늘 통화, 마음에 들었어?'),
                    child: FeedbackStarRating(
                      value: answers.rating,
                      onChanged: controller.setRating,
                    ),
                  ),
                  RequiredFeedbackQuestion(
                    title: numbered(
                      '${withConjunctiveParticle(characterName)} 또 통화하고 싶어?',
                    ),
                    child: FeedbackChoiceGroup<RevisitIntention>(
                      values: RevisitIntention.values,
                      labelOf: (intention) => intention.label,
                      selectedValues: {?answers.revisitIntention},
                      onTap: controller.setRevisitIntention,
                      columnCount: _choiceColumnCount,
                    ),
                  ),
                  if (previousCallRecallRequired)
                    RequiredFeedbackQuestion(
                      title: numbered(
                        '${withSubjectParticle(characterName)} 지난 대화를 기억했어?',
                      ),
                      hint: '(단일 선택)',
                      child: FeedbackChoiceGroup<PreviousCallRecall>(
                        values: PreviousCallRecall.values,
                        labelOf: (recall) => recall.label,
                        selectedValues: {?answers.previousCallRecall},
                        onTap: controller.setPreviousCallRecall,
                        columnCount: _choiceColumnCount,
                      ),
                    ),
                  RequiredFeedbackQuestion(
                    title: numbered('어색했던 순간이 있었어?'),
                    hint: '(복수 선택)',
                    child: FeedbackChoiceGroup<AwkwardMoment>(
                      values: AwkwardMoment.values,
                      labelOf: (moment) => moment.label,
                      selectedValues: answers.awkwardMoments,
                      onTap: controller.toggleAwkwardMoment,
                      columnCount: _choiceColumnCount,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              horizontalMargin,
              AppSpacing.space12,
              horizontalMargin,
              AppSpacing.space10,
            ),
            child: PrimaryFilledButton(
              label: '의견 보내기',
              onPressed: canSubmit
                  ? () => unawaited(_submit(context, ref))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
