import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 울리는 화면의 "밀어서 통화하기" 슬라이더. 손잡이는 손가락을 따라 가로로만 움직이고,
/// 오른쪽 끝에 닿으면 [onCompleted]를 한 번만 부른다. 끝에 닿기 전에 놓으면 처음 자리로 돌아간다.
/// 디자이너가 정하지 않은 되돌아가기 애니메이션은 넣지 않는다.
class CallSlideToAnswer extends StatefulWidget {
  const CallSlideToAnswer({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<CallSlideToAnswer> createState() => _CallSlideToAnswerState();
}

class _CallSlideToAnswerState extends State<CallSlideToAnswer> {
  static const String _label = '밀어서 통화하기';
  // 손잡이와 트랙 가장자리 사이 여백. 시안 높이에서 손잡이 크기를 뺀 값의 절반이다.
  static const double _handleInset =
      (AppLayout.callSlideToAnswerHeight - AppLayout.callSlideHandleSize) / 2;

  double _handleOffset = 0;
  bool _isCompleted = false;

  void _complete() {
    if (_isCompleted) {
      return;
    }
    _isCompleted = true;
    widget.onCompleted();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maximumOffset) {
    if (_isCompleted) {
      return;
    }
    final currentOffset = math.min(_handleOffset, maximumOffset);
    final nextOffset = (currentOffset + details.delta.dx).clamp(
      0.0,
      maximumOffset,
    );
    setState(() => _handleOffset = nextOffset);
    // 손잡이가 움직일 자리가 없는 폭에서는 끌기만으로 완료하지 않는다.
    if (maximumOffset > 0 && nextOffset >= maximumOffset) {
      _complete();
    }
  }

  void _handleDragEnd() {
    if (_isCompleted) {
      return;
    }
    setState(() => _handleOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label,
      onTap: _complete,
      excludeSemantics: true,
      child: SizedBox(
        height: AppLayout.callSlideToAnswerHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maximumOffset = math.max(
              0.0,
              constraints.maxWidth -
                  AppLayout.callSlideHandleSize -
                  2 * _handleInset,
            );
            // 폭이 줄면 손잡이가 트랙 밖으로 나가지 않도록 다시 맞춘다.
            final handleOffset = math.min(_handleOffset, maximumOffset);
            return DecoratedBox(
              decoration: const ShapeDecoration(
                color: AppColors.callSlideTrack,
                shape: StadiumBorder(),
              ),
              child: Stack(
                children: [
                  // 문구는 손잡이 오른쪽에 남는 영역의 가운데에 놓는다.
                  Positioned.fill(
                    left: AppLayout.callSlideHandleSize + _handleInset,
                    right: _handleInset,
                    child: Center(
                      child: Text(
                        _label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading20Regular.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _handleInset + handleOffset,
                    top: _handleInset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) =>
                          _handleDragUpdate(details, maximumOffset),
                      onHorizontalDragEnd: (_) => _handleDragEnd(),
                      onHorizontalDragCancel: _handleDragEnd,
                      child: const _CallSlideHandle(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 흰 원 위에 통화 글리프를 얹은 슬라이더 손잡이.
class _CallSlideHandle extends StatelessWidget {
  const _CallSlideHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppLayout.callSlideHandleSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(AppAssets.callSlideHandleBackground),
          SizedBox.square(
            dimension: AppLayout.callSlideHandleIconBoxSize,
            child: Center(child: SvgPicture.asset(AppAssets.callAnswerIcon)),
          ),
        ],
      ),
    );
  }
}
