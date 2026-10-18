import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 부모가 준 폭을 디자인 프레임 폭으로 나눈 배율을 [builder]에 넘긴다.
/// 장식처럼 화면 폭에 비례해야 하는 크기를 계산할 때 쓴다.
class DesignFrameScaleBuilder extends StatelessWidget {
  const DesignFrameScaleBuilder({
    super.key,
    required this.builder,
    this.designWidth = AppLayout.figmaFrameWidth,
  });

  final Widget Function(BuildContext context, double scale) builder;
  final double designWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.maxWidth.isFinite,
          'DesignFrameScaleBuilder는 폭이 정해진 부모 안에서만 쓸 수 있다.',
        );
        return builder(context, constraints.maxWidth / designWidth);
      },
    );
  }
}
