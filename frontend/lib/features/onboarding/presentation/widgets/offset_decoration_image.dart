import 'package:flutter/material.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';

/// 부모 중심에서 [offset]만큼 옮긴 위치에 [width]x[height]로 이미지를 그린다.
/// 부모보다 커도 오버플로 경고 없이 그려지며, 잘림은 바깥에서 정한다.
class OffsetDecorationImage extends StatelessWidget {
  const OffsetDecorationImage({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.offset = Offset.zero,
  });

  final String assetPath;
  final double width;
  final double height;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: OverflowBox(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
        maxHeight: height,
        child: SoftGlowDecoration(
          assetPath: assetPath,
          width: width,
          height: height,
        ),
      ),
    );
  }
}
