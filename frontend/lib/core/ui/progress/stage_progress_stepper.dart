import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 생성 단계 하나의 진행 상태.
enum StageProgressStatus { completed, inProgress, pending }

/// 단계 원과 연결선, 라벨을 가로로 나열하는 단계 표시기. 각 단계는 같은 폭의 열을 차지한다.
class StageProgressStepper extends StatelessWidget {
  // 목록 길이 assert는 const 표현식이 아니어서 const 생성자로 만들 수 없다.
  // ignore: prefer_const_constructors_in_immutables
  StageProgressStepper({
    super.key,
    required this.labels,
    required this.statuses,
  }) : assert(
         labels.length == statuses.length,
         'labels and statuses must have the same length',
       );

  final List<String> labels;
  final List<StageProgressStatus> statuses;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = constraints.maxWidth / labels.length;
              return Stack(
                children: [
                  for (var index = 0; index < labels.length - 1; index++)
                    Positioned(
                      left:
                          columnWidth * (index + 0.5) +
                          AppLayout.iconSize / 2 +
                          AppSpacing.space4,
                      width:
                          columnWidth -
                          AppLayout.iconSize -
                          AppSpacing.space4 * 2,
                      top:
                          (AppLayout.iconSize -
                              AppLayout.stageConnectorThickness) /
                          2,
                      child: _StageConnector(
                        leadingStatus: statuses[index],
                        trailingStatus: statuses[index + 1],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: _StageColumn(
                  label: labels[index],
                  status: statuses[index],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({required this.label, required this.status});

  final String label;
  final StageProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == StageProgressStatus.pending;
    return Column(
      children: [
        _StageIndicator(status: status),
        const SizedBox(height: AppSpacing.space8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption12.copyWith(
            color: isPending ? AppColors.neutralSurface : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.status});

  final StageProgressStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.iconSize,
      height: AppLayout.iconSize,
      child: switch (status) {
        StageProgressStatus.inProgress => Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(AppAssets.stageInProgressRingIcon),
            const SizedBox(
              width: AppLayout.stageIndicatorDotSize,
              height: AppLayout.stageIndicatorDotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accentStrong,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        _ => DecoratedBox(
          decoration: BoxDecoration(
            color: status == StageProgressStatus.completed
                ? AppColors.accentStrong
                : AppColors.neutralSurface,
            shape: BoxShape.circle,
          ),
          child: Center(child: SvgPicture.asset(AppAssets.checkIcon)),
        ),
      },
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector({
    required this.leadingStatus,
    required this.trailingStatus,
  });

  final StageProgressStatus leadingStatus;
  final StageProgressStatus trailingStatus;

  List<Color> get _colors {
    if (leadingStatus != StageProgressStatus.completed) {
      return const [AppColors.background, AppColors.neutralSurface];
    }
    return trailingStatus == StageProgressStatus.completed
        ? const [AppColors.accentStrong, AppColors.accentStrong]
        : const [AppColors.accentStrong, AppColors.background];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.stageConnectorThickness,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: _colors)),
      ),
    );
  }
}
