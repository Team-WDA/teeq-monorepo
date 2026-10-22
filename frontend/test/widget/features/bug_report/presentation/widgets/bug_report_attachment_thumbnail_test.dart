import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_attachment_thumbnail.dart';

const _devicePixelRatio = 3.0;

Widget _app() => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(devicePixelRatio: _devicePixelRatio),
    child: BugReportAttachmentThumbnail(
      imagePath: '/not/existing/photo.jpg',
      onDeletePressed: () {},
    ),
  ),
);

void main() {
  testWidgets('thumbnail_decodesWithBoundedSizeKeepingAspectRatio', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    final provider = tester.widget<Image>(find.byType(Image)).image;
    final expectedSize = (AppLayout.bugReportAttachmentSize * _devicePixelRatio)
        .round();
    expect(provider, isA<ResizeImage>());
    final resizeImage = provider as ResizeImage;
    expect(resizeImage.width, expectedSize);
    expect(resizeImage.height, expectedSize);
    expect(resizeImage.policy, ResizeImagePolicy.fit);
  });

  testWidgets('thumbnail_unreadableFile_keepsPlaceholderWithDeleteButton', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.byType(ColoredBox), findsWidgets);
    expect(find.bySemanticsLabel('첨부 사진 삭제'), findsOneWidget);
  });
}
