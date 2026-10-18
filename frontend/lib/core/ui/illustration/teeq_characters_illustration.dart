import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';

/// 시작 화면의 Teeq 캐릭터 일러스트. 372:388 비율을 유지하며 폭에 맞춰 줄어든다.
class TeeqCharactersIllustration extends StatelessWidget {
  const TeeqCharactersIllustration({super.key});

  static const double _aspectRatio = 372 / 388;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Image.asset(
        AppAssets.teeqCharactersIllustration,
        fit: BoxFit.contain,
      ),
    );
  }
}
