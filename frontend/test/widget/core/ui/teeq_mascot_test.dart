import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

void main() {
  testWidgets('mascot_rendersEachPoseAtGivenWidth', (tester) async {
    const mascotWidth = 120.0;
    for (final pose in TeeqMascotPose.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: TeeqMascot(pose: pose, width: mascotWidth),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, mascotWidth, reason: pose.name);
      expect(image.excludeFromSemantics, isTrue, reason: pose.name);
      expect(tester.takeException(), isNull, reason: pose.name);
    }
  });
}
