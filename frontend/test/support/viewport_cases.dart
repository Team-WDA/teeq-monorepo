import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 폭별 레이아웃 테스트에 쓰는 화면 크기와 글자 배율 조합.
class ViewportCase {
  const ViewportCase({
    required this.width,
    required this.height,
    required this.textScale,
  });

  final double width;
  final double height;
  final double textScale;

  String get label => '${width}x$height@$textScale';
}

/// 폭 320/375/393/430 각각을 글자 배율 1.0과 1.2로 확인하는 조합.
const List<ViewportCase> viewportCases = [
  ViewportCase(width: 320, height: 568, textScale: 1.0),
  ViewportCase(width: 320, height: 568, textScale: 1.2),
  ViewportCase(width: 375, height: 667, textScale: 1.0),
  ViewportCase(width: 375, height: 667, textScale: 1.2),
  ViewportCase(width: 393, height: 852, textScale: 1.0),
  ViewportCase(width: 393, height: 852, textScale: 1.2),
  ViewportCase(width: 430, height: 932, textScale: 1.0),
  ViewportCase(width: 430, height: 932, textScale: 1.2),
];

/// [viewport]의 논리 크기와 글자 배율로 [widget]을 그린다. 테스트가 끝나면 설정을 되돌린다.
Future<void> pumpAtViewport(
  WidgetTester tester,
  ViewportCase viewport,
  Widget widget,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(viewport.width, viewport.height);
  tester.platformDispatcher.textScaleFactorTestValue = viewport.textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}
