import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// 플로팅 버블의 좌상단 좌표를 [safePadding]을 뺀 화면 안쪽으로 제한한다.
///
/// 사용할 수 있는 영역이 버블보다 작으면 안전 영역의 좌상단 모서리를 돌려준다.
Offset clampBubbleOffset({
  required Offset offset,
  required Size screenSize,
  required EdgeInsets safePadding,
  required double bubbleDiameter,
}) {
  final minimumX = safePadding.left;
  final minimumY = safePadding.top;
  final maximumX = screenSize.width - safePadding.right - bubbleDiameter;
  final maximumY = screenSize.height - safePadding.bottom - bubbleDiameter;
  return Offset(
    math.max(minimumX, math.min(offset.dx, maximumX)),
    math.max(minimumY, math.min(offset.dy, maximumY)),
  );
}
