import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/text_field/underline_labeled_text_field.dart';

Widget _buildLayout({VoidCallback? onBackPressed}) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.2),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ),
      child: child!,
    ),
    home: BottomActionScreenLayout(
      onBackPressed: onBackPressed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitleWithDescriptionHeading(
            title: '이메일로\n시작하기',
            description: '이메일과 비밀번호를\n입력해 주세요',
          ),
          UnderlineLabeledTextField(
            label: '이메일',
            hintText: '이메일을 입력하세요',
            controller: emailController,
          ),
          UnderlineLabeledTextField(
            label: '비밀번호',
            hintText: '비밀번호를 입력하세요',
            controller: passwordController,
            obscureText: true,
          ),
        ],
      ),
      bottomAction: PrimaryFilledButton(label: '다음', onPressed: () {}),
    ),
  );
}

void main() {
  testWidgets('320x568, 글자 1.2배, 키보드 노출 상태에서도 오버플로 없이 버튼이 보인다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildLayout());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('다음'), findsOneWidget);
    expect(
      tester.getRect(find.byType(PrimaryFilledButton)).bottom,
      lessThanOrEqualTo(568 - 300),
    );
  });

  testWidgets('onBackPressed가 있을 때만 뒤로 가기 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(_buildLayout());
    expect(find.byType(AppBackButton), findsNothing);

    var backPressedCount = 0;
    await tester.pumpWidget(
      _buildLayout(onBackPressed: () => backPressedCount++),
    );
    expect(find.byType(AppBackButton), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    expect(backPressedCount, 1);
  });

  testWidgets('isContentScrollable이 false이면 본문이 스크롤되지 않고 기본값에서는 스크롤된다', (
    tester,
  ) async {
    Future<double> dragAndReadScrollPixels({required bool? scrollable}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: scrollable == null
              ? const BottomActionScreenLayout(
                  content: SizedBox(height: 2000),
                  bottomAction: SizedBox(height: 40),
                )
              : BottomActionScreenLayout(
                  isContentScrollable: scrollable,
                  content: const SizedBox(height: 2000),
                  bottomAction: const SizedBox(height: 40),
                ),
        ),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      return tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
    }

    expect(await dragAndReadScrollPixels(scrollable: false), 0);
    expect(await dragAndReadScrollPixels(scrollable: null), greaterThan(0));
  });
}
