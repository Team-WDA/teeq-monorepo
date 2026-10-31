import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 생성 단계 하나의 진행 상태.
enum StageProgressStatus { completed, inProgress, pending }

/// 단계 원과 연결선, 라벨을 가로로 나열하는 단계 표시기. 각 단계는 같은 폭의 열을 차지한다.
/// [progress](0.0~1.0)에 따라 단계 상태와 연결선 채움이 이어서 바뀐다. 첫 단계는 항상 완료다.
class StageProgressStepper extends StatelessWidget {
  const StageProgressStepper({
    super.key,
    required this.labels,
    required this.progress,
  });

  final List<String> labels;
  final double progress;

  /// 단계 k는 progress가 k/n 이상이면 완료, (k-1)/n 이상이면 진행 중, 아니면 대기다.
  StageProgressStatus _statusAt(int stageIndex) {
    if (stageIndex == 0) {
      return StageProgressStatus.completed;
    }
    final stageCount = labels.length;
    if (progress >= stageIndex / stageCount) {
      return StageProgressStatus.completed;
    }
    if (progress >= (stageIndex - 1) / stageCount) {
      return StageProgressStatus.inProgress;
    }
    return StageProgressStatus.pending;
  }

  /// 연결선 j(단계 j와 j+1 사이)의 채움 비율. 첫 연결선은 항상 가득 차고,
  /// 나머지는 단계 j+1이 진행 중인 구간(j/n~(j+1)/n)에 비례해 찬다.
  double _connectorFillAt(int connectorIndex) {
    if (connectorIndex == 0) {
      return 1;
    }
    final stageCount = labels.length;
    return ((progress - connectorIndex / stageCount) * stageCount).clamp(
      0.0,
      1.0,
    );
  }

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
                        fillFraction: _connectorFillAt(index),
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
                  status: _statusAt(index),
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
          style: AppTextStyles.caption12SemiBold.copyWith(
            color: isPending
                ? AppColors.neutralSurface
                : AppColors.textSecondary,
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
  const _StageConnector({required this.fillFraction});

  /// 왼쪽부터 강조색으로 채울 비율(0.0~1.0). 나머지는 대기 연결선 색으로 둔다.
  final double fillFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.stageConnectorThickness,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.neutralSurface],
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fillFraction,
          heightFactor: 1,
          child: const ColoredBox(color: AppColors.accentStrong),
        ),
      ),
    );
  }
}
