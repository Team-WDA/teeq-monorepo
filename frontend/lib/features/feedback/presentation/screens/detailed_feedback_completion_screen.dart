import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_character_name_builder.dart';

/// 상세 피드백을 보낸 뒤의 완료 화면. 뒤로 가기는 막고 "홈으로 가기"로만 나간다.
class DetailedFeedbackCompletionScreen extends ConsumerWidget {
  const DetailedFeedbackCompletionScreen({
    super.key,
    required this.callSessionId,
  });

  final String callSessionId;

  /// 홈으로 나가며 흐름 상태를 비운다. 이동을 먼저 해야 남아 있는 화면이 빈 상태로 다시 그려지지 않는다.
  void _exitToHome(BuildContext context, WidgetRef ref) {
    context.go(AppRoutes.home);
    ref.read(feedbackFlowControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: FeedbackCharacterNameBuilder(
        builder: (context, characterName) => Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: AppLayout.detailedCompletionMascotTopOffset,
                        ),
                        // 마스코트는 좌우 여백 없이 화면 폭을 가득 채운다.
                        LayoutBuilder(
                          builder: (context, constraints) => TeeqMascot(
                            pose: TeeqMascotPose.celebration,
                            width: constraints.maxWidth,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLayout.horizontalMargin,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.space24,
                            children: [
                              const Text(
                                '피드백을\n보내줬어!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.display32Bold,
                              ),
                              Text(
                                '소중한 의견 덕분에\n'
                                '${withSubjectParticle(characterName)} '
                                '조금 더 성장할 수 있을 거야.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body16RegularMultiline
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.horizontalMargin,
                    0,
                    AppLayout.horizontalMargin,
                    AppSpacing.space12,
                  ),
                  child: PrimaryFilledButton(
                    label: '홈으로 가기',
                    onPressed: () => _exitToHome(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
