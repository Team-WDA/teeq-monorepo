import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 배경에 은은하게 깔리는 빛 번짐 장식. 에셋 확장자에 따라 SVG 또는 비트맵으로 그린다.
class SoftGlowDecoration extends StatelessWidget {
  const SoftGlowDecoration({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: isSvg
            ? SvgPicture.asset(assetPath, fit: BoxFit.fill)
            : Image.asset(assetPath, fit: BoxFit.fill),
      ),
    );
  }
}
