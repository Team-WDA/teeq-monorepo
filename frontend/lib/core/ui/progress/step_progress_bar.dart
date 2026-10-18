import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';

/// 전체 단계 중 현재 단계까지를 채워 보여 주는 가로 진행 바.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(totalSteps > 0, 'totalSteps must be positive'),
       assert(
         currentStep > 0 && currentStep <= totalSteps,
         'currentStep must be within 1..totalSteps',
       );

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusSm,
      child: SizedBox(
        height: AppLayout.stepProgressBarHeight,
        child: ColoredBox(
          color: AppColors.borderSubtle,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: currentStep / totalSteps,
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.accentStrong),
            ),
          ),
        ),
      ),
    );
  }
}
