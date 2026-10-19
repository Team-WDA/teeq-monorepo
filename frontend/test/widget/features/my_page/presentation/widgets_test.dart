import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/ui/button/destructive_tonal_button.dart';
import 'package:teeq/features/my_page/presentation/widgets/profile_summary_card.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_row.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_section_card.dart';

import '../../../../support/viewport_cases.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Finder _networkImage() => find.byWidgetPredicate(
  (widget) => widget is Image && widget.image is NetworkImage,
);

Finder _defaultAvatar() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName ==
          AppAssets.defaultAvatarIllustration,
);

void main() {
  testWidgets('ProfileSummaryCard shows nickname and email', (tester) async {
    await tester.pumpWidget(
      _host(const ProfileSummaryCard(nickname: '소연', email: 'a@teeq.com')),
    );

    expect(find.text('소연'), findsOneWidget);
    expect(find.text('a@teeq.com'), findsOneWidget);
  });

  testWidgets('ProfileSummaryCard omits email area when email is null', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ProfileSummaryCard(nickname: '소연')));

    expect(find.text('소연'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('falls back to default avatar when url is null', (tester) async {
    await tester.pumpWidget(_host(const ProfileSummaryCard(nickname: '소연')));

    expect(_networkImage(), findsNothing);
    expect(_defaultAvatar(), findsOneWidget);
  });

  testWidgets('falls back to default avatar when image fails', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileSummaryCard(
          nickname: '소연',
          profileImageUrl: 'https://a.kr/media/profile-images/a.png',
        ),
      ),
    );
    // 테스트 환경의 HTTP 요청은 실패하므로 errorBuilder가 기본 아바타를 그린다.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(_defaultAvatar(), findsOneWidget);
  });

  testWidgets('uses given absolute url as is', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileSummaryCard(
          nickname: '소연',
          profileImageUrl: 'https://a.kr/media/profile-images/a.png',
        ),
      ),
    );

    final image = tester.widget<Image>(_networkImage());
    expect(
      (image.image as NetworkImage).url,
      'https://a.kr/media/profile-images/a.png',
    );
  });

  testWidgets('SettingsSectionCard shows title, rows and dividers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsSectionCard(
          title: '서비스',
          rows: [
            SettingsRow(
              label: '첫째',
              leadingIconAssetPath: AppAssets.documentIcon,
              showsChevron: true,
            ),
            SettingsRow(
              label: '둘째',
              leadingIconAssetPath: AppAssets.mailIcon,
              value: '값',
            ),
          ],
        ),
      ),
    );

    expect(find.text('서비스'), findsOneWidget);
    expect(find.text('첫째'), findsOneWidget);
    expect(find.text('둘째'), findsOneWidget);
    expect(find.text('값'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('email value uses remaining width', (tester) async {
    // flutter_test 기본 폰트는 글자마다 1em이다. 값 글자 크기 12 기준
    // 'soyeon.kim@teeq.kr'(18자)은 18*12=216px이다.
    // 393 폭에서 행의 남는 폭은 393-48-32-24-12-42(라벨 3자*14)-12=223px이라
    // 새 레이아웃은 한 줄로 들어간다. 라벨 Expanded와 값 Flexible이 남는 폭을
    // 나눠 값이 약 132.5px만 쓰던 이전 레이아웃은 말줄임이 되므로 이 테스트로 변경을 구별한다.
    const email = 'soyeon.kim@teeq.kr';
    await pumpAtViewport(
      tester,
      viewportCases.firstWhere(
        (viewport) => viewport.width == 393 && viewport.textScale == 1.0,
      ),
      _host(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SettingsSectionCard(
            title: '계정',
            rows: [
              SettingsRow(
                label: '이메일',
                leadingIconAssetPath: AppAssets.mailIcon,
                value: email,
              ),
            ],
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text(email));
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets(
    'very long email ellipsizes without overflow at 320 and text scale 1.2',
    (tester) async {
      await pumpAtViewport(
        tester,
        viewportCases.firstWhere(
          (viewport) => viewport.width == 320 && viewport.textScale == 1.2,
        ),
        _host(
          const SettingsRow(
            label: '이메일',
            leadingIconAssetPath: AppAssets.mailIcon,
            value: 'a-very-long-email-address-for-overflow-check.soyeon.kim@teeq.kr',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('@teeq.kr'),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
    },
  );

  testWidgets('row without value keeps chevron at the right edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsRow(
          label: '이용약관',
          leadingIconAssetPath: AppAssets.documentIcon,
          showsChevron: true,
        ),
      ),
    );

    final rowRight = tester.getRect(find.byType(SettingsRow)).right;
    final chevronRight = tester.getRect(find.byType(SvgPicture).last).right;
    // 행의 오른쪽 안쪽 여백(16)만큼만 떨어져 있어야 한다.
    expect(rowRight - chevronRight, 16);
  });

  testWidgets('DestructiveTonalButton taps only when enabled', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            DestructiveTonalButton(label: '켜짐', onPressed: () => tapCount++),
            const DestructiveTonalButton(label: '꺼짐', onPressed: null),
          ],
        ),
      ),
    );

    await tester.tap(find.text('켜짐'));
    await tester.tap(find.text('꺼짐'));

    expect(tapCount, 1);
  });

  testWidgets('DestructiveTonalButton meets tap target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(DestructiveTonalButton(label: '로그아웃', onPressed: () {})),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
