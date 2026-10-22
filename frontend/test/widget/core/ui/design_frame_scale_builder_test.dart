import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';

import '../../../support/viewport_cases.dart';

Widget _scaleProbe({
  double? designWidth,
  required ValueChanged<double> onScale,
}) {
  final probe = designWidth == null
      ? DesignFrameScaleBuilder(
          builder: (context, scale) {
            onScale(scale);
            return const SizedBox.shrink();
          },
        )
      : DesignFrameScaleBuilder(
          designWidth: designWidth,
          builder: (context, scale) {
            onScale(scale);
            return const SizedBox.shrink();
          },
        );
  return probe;
}

void main() {
  const screen = ViewportCase(width: 393, height: 852, textScale: 1.0);

  testWidgets('scale is width divided by design width', (tester) async {
    double? scale;
    await pumpAtViewport(
      tester,
      screen,
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              width: 393,
              child: _scaleProbe(onScale: (value) => scale = value),
            ),
          ],
        ),
      ),
    );
    expect(scale, 1.0);

    await pumpAtViewport(
      tester,
      screen,
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              width: 196.5,
              child: _scaleProbe(onScale: (value) => scale = value),
            ),
          ],
        ),
      ),
    );
    expect(scale, 0.5);
  });

  testWidgets('custom design width', (tester) async {
    double? scale;
    await pumpAtViewport(
      tester,
      screen,
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              width: 345,
              child: _scaleProbe(
                designWidth: 345,
                onScale: (value) => scale = value,
              ),
            ),
          ],
        ),
      ),
    );
    expect(scale, 1.0);
  });

  testWidgets('uses parent constraints not screen width', (tester) async {
    double? scale;
    await pumpAtViewport(
      tester,
      screen,
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              width: 200,
              child: _scaleProbe(onScale: (value) => scale = value),
            ),
          ],
        ),
      ),
    );
    expect(scale, 200 / 393);
  });

  testWidgets('pumpAtViewport applies size and text scale', (tester) async {
    late Size size;
    late double scaledTen;
    await pumpAtViewport(
      tester,
      const ViewportCase(width: 320, height: 568, textScale: 1.2),
      MaterialApp(
        home: Builder(
          builder: (context) {
            size = MediaQuery.sizeOf(context);
            scaledTen = MediaQuery.textScalerOf(context).scale(10);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(size, const Size(320, 568));
    expect(scaledTen, closeTo(12, 1e-9));
  });
}
