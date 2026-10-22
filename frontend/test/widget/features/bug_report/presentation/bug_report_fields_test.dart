import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/bug_report/domain/bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/data/image_picker_bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_content_field.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_image_attachment_field.dart';

import '../../../../support/fake_bug_report_image_picker.dart';

Widget _app(Widget child, {BugReportImagePicker? picker}) => ProviderScope(
  overrides: [
    if (picker != null) bugReportImagePickerProvider.overrideWithValue(picker),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

class _ImageFieldHost extends StatefulWidget {
  const _ImageFieldHost({this.initial = const []});

  final List<String> initial;

  @override
  State<_ImageFieldHost> createState() => _ImageFieldHostState();
}

class _ImageFieldHostState extends State<_ImageFieldHost> {
  late List<String> _paths = widget.initial;

  @override
  Widget build(BuildContext context) => BugReportImageAttachmentField(
    imagePaths: _paths,
    onChanged: (paths) => setState(() => _paths = paths),
  );
}

void main() {
  testWidgets('contentField_showsCounterAndStopsAt2000', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(BugReportContentField(controller: controller)),
    );

    expect(find.text('0/2000'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a' * 2500);
    await tester.pump();

    expect(controller.text.length, 2000);
    expect(find.text('2000/2000'), findsOneWidget);
  });

  testWidgets('contentField_limitsByUtf16CodeUnitsNotGraphemes', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(BugReportContentField(controller: controller)),
    );

    // 이모지 하나는 UTF-16 코드 유닛 2개다. 1500개면 3000 유닛이라 2000 유닛(1000개)에서 멈춘다.
    await tester.enterText(find.byType(TextField), '😀' * 1500);
    await tester.pump();

    expect(controller.text.length, 2000);
    expect(find.text('2000/2000'), findsOneWidget);
  });

  testWidgets('imageField_limitsToFiveImages', (tester) async {
    final picker = FakeBugReportImagePicker(
      result: ['b1.jpg', 'b2.jpg', 'b3.jpg', 'b4.jpg'],
    );
    await tester.pumpWidget(
      _app(
        const _ImageFieldHost(initial: ['a1.jpg', 'a2.jpg']),
        picker: picker,
      ),
    );

    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();

    expect(picker.lastLimit, 3);
    // 선택기가 한도를 무시하고 4장을 돌려줘도 5장까지만 붙는다.
    expect(find.bySemanticsLabel('첨부 사진 삭제'), findsNWidgets(5));
    expect(find.text('사진 추가'), findsNothing);
  });

  testWidgets('imageField_deletesSingleImage', (tester) async {
    await tester.pumpWidget(
      _app(
        const _ImageFieldHost(initial: ['a1.jpg', 'a2.jpg']),
        picker: FakeBugReportImagePicker(),
      ),
    );

    await tester.tap(find.bySemanticsLabel('첨부 사진 삭제').first);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('첨부 사진 삭제'), findsOneWidget);
  });
}
