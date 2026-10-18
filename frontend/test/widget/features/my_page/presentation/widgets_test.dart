import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/ui/button/destructive_tonal_button.dart';
import 'package:teeq/features/my_page/presentation/widgets/profile_summary_card.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_row.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_section_card.dart';

import '../../../../support/my_page_harness.dart';

Widget _host(Widget child, {AppConfig config = testAppConfig}) {
  return ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
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
          profileImageUrl: '/media/profile-images/a.png',
        ),
      ),
    );
    // 테스트 환경의 HTTP 요청은 실패하므로 errorBuilder가 기본 아바타를 그린다.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(_defaultAvatar(), findsOneWidget);
  });

  testWidgets('avatar url joins base url without double slash', (tester) async {
    const config = AppConfig(
      apiBaseUrl: 'https://a.kr/',
      appleServiceId: 'x',
      appleRedirectUri: 'x',
    );
    await tester.pumpWidget(
      _host(
        const ProfileSummaryCard(
          nickname: '소연',
          profileImageUrl: '/media/profile-images/a.png',
        ),
        config: config,
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
