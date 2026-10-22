import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/neutral_filled_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/option_card/selectable_option_card.dart';
import 'package:teeq/core/ui/progress/step_progress_bar.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';

/// 온보딩 질문 7개를 한 화면에서 인덱스로 전환하며 보여 주는 화면.
class OnboardingQuestionScreen extends ConsumerWidget {
  const OnboardingQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterSetupFlowControllerProvider);
    final controller = ref.read(characterSetupFlowControllerProvider.notifier);
    final question = OnboardingQuestion.values[state.questionIndex];
    final selected = state.selections.selectedFor(question);
    final isLastQuestion =
        state.questionIndex == OnboardingQuestion.values.length - 1;
    final selectionGuide = question.isMultipleChoice ? '(복수 선택)' : '(단일 선택)';

    final nextButton = PrimaryFilledButton(
      label: '다음',
      onPressed: state.selections.isAnswered(question)
          ? () {
              if (isLastQuestion) {
                context.go(AppRoutes.onboardingGenerating);
              } else {
                controller.goToNextQuestion();
              }
            }
          : null,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (state.questionIndex > 0) {
          controller.goToPreviousQuestion();
        } else if (state.mode == CharacterSetupMode.edit) {
          controller.reset();
          context.go(AppRoutes.home);
        }
      },
      child: BottomActionScreenLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.space24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.stepProgressBarHorizontalInset,
              ),
              child: StepProgressBar(
                currentStep: state.questionIndex + 1,
                totalSteps: OnboardingQuestion.values.length,
              ),
            ),
            const SizedBox(height: AppSpacing.space40),
            ScreenTitleWithDescriptionHeading(
              title: question.title,
              description: '${question.description} $selectionGuide',
            ),
            const SizedBox(height: AppSpacing.space24),
            for (final option in question.options) ...[
              SelectableOptionCard(
                label: option.label,
                isSelected: selected.contains(option),
                onTap: () => controller.toggleOption(option),
              ),
              const SizedBox(height: AppSpacing.space8),
            ],
          ],
        ),
        bottomAction: state.questionIndex > 0
            ? Row(
                children: [
                  Expanded(
                    child: NeutralFilledButton(
                      label: '이전',
                      onPressed: controller.goToPreviousQuestion,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(flex: 2, child: nextButton),
                ],
              )
            : nextButton,
      ),
    );
  }
}
