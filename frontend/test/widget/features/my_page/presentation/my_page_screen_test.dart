import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';
import 'package:teeq/features/bug_report/presentation/bug_report_screen.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';
import 'package:teeq/features/my_page/presentation/legal_document_screen.dart';
import 'package:teeq/features/my_page/presentation/my_page_screen.dart';
import 'package:teeq/features/my_page/presentation/nickname_change_screen.dart';

import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

Future<void> _pumpMyPage(
  WidgetTester tester,
  MyPageHarness harness, {
  ViewportCase viewport = _defaultViewport,
}) => pumpAtViewport(tester, viewport, harness.app(const MyPageScreen()));

void main() {
  testWidgets('refreshes member on entry so email appears', (tester) async {
    final harness = MyPageHarness(
      fetchedMember: memberWithoutEmail.copyWith(email: 'soyeon@teeq.com'),
    );
    await _pumpMyPage(tester, harness);

    expect(harness.repository.fetchMeCount, 1);
    // 프로필 카드와 이메일 행에 모두 보인다.
    expect(find.text('soyeon@teeq.com'), findsNWidgets(2));
  });

  testWidgets('reports refresh failure to the error handler', (tester) async {
    final harness = MyPageHarness(fetchMeError: Exception('offline'));
    await _pumpMyPage(tester, harness);

    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('shows title, sections and buttons', (tester) async {
    final harness = MyPageHarness();
    await _pumpMyPage(tester, harness);

    for (final text in [
      '마이',
      '소연',
      '계정 정보',
      '이메일',
      '서비스 (앱정보 v0.15.0)',
      '서비스 이용약관',
      '개인정보 처리방침',
      '로그아웃',
      '회원 탈퇴',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('shows version in service section title', (tester) async {
    await _pumpMyPage(tester, MyPageHarness());

    expect(find.text('서비스 (앱정보 v0.15.0)'), findsOneWidget);
  });

  testWidgets('shows only service while version is loading', (tester) async {
    final completer = Completer<String>();
    final harness = MyPageHarness(
      appVersionOverride: appVersionProvider.overrideWith(
        (ref) => completer.future,
      ),
    );
    await _pumpMyPage(tester, harness);

    expect(find.text('서비스'), findsOneWidget);
    expect(find.textContaining('앱정보'), findsNothing);
  });

  testWidgets('shows only service when version fails and reports no error', (
    tester,
  ) async {
    final harness = MyPageHarness(
      appVersionOverride: appVersionProvider.overrideWith(
        (ref) async => throw Exception('plugin unavailable'),
      ),
    );
    await _pumpMyPage(tester, harness);

    expect(find.text('서비스'), findsOneWidget);
    expect(find.textContaining('앱정보'), findsNothing);
    expect(harness.errorHandler.handledErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('google login member sees google login row and no password row', (
    tester,
  ) async {
    await _pumpMyPage(tester, MyPageHarness());

    expect(find.text('Google로 로그인 중이에요!'), findsOneWidget);
    expect(find.text('Apple로 로그인 중이에요!'), findsNothing);
    expect(find.text('비밀번호 변경'), findsNothing);
  });

  testWidgets('apple login member sees apple login row', (tester) async {
    final harness = MyPageHarness(
      member: memberWithoutEmail.copyWith(loginType: LoginType.apple),
    );
    await _pumpMyPage(tester, harness);

    expect(find.text('Apple로 로그인 중이에요!'), findsOneWidget);
    expect(find.text('Google로 로그인 중이에요!'), findsNothing);
    expect(find.text('비밀번호 변경'), findsNothing);
  });

  testWidgets('logout tap calls logout immediately', (tester) async {
    final harness = MyPageHarness();
    await _pumpMyPage(tester, harness);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(harness.repository.logoutCount, 1);
    expect(harness.currentMember, isNull);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('double tap on logout calls logout once', (tester) async {
    final harness = MyPageHarness();
    harness.repository.logoutGate = Completer<void>();
    await _pumpMyPage(tester, harness);

    final logoutButton = find.text('로그아웃');
    await tester.tap(logoutButton);
    await tester.tap(logoutButton);

    expect(harness.repository.logoutCount, 1);
    harness.repository.logoutGate!.complete();
    await tester.pumpAndSettle();
  });

  for (final (label, type) in [
    ('서비스 이용약관', LegalDocumentType.serviceTerms),
    ('개인정보 처리방침', LegalDocumentType.privacyPolicy),
  ]) {
    testWidgets('$label row opens the $type document screen', (tester) async {
      final harness = MyPageHarness();
      await pumpAtViewport(tester, _defaultViewport, harness.routedApp());

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.byType(MyPageScreen), findsNothing);
      expect(
        tester
            .widget<LegalDocumentScreen>(find.byType(LegalDocumentScreen))
            .type,
        type,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('myPage_showsBugReportRowAndNavigates', (tester) async {
    final harness = MyPageHarness();
    await pumpAtViewport(tester, _defaultViewport, harness.routedApp());

    expect(find.text('버그 제보'), findsOneWidget);

    await tester.tap(find.text('버그 제보'));
    await tester.pumpAndSettle();

    expect(find.byType(MyPageScreen), findsNothing);
    expect(find.byType(BugReportScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile card exposes a button semantics that opens nickname change',
    (tester) async {
      final handle = tester.ensureSemantics();
      final harness = MyPageHarness();
      await pumpAtViewport(tester, _defaultViewport, harness.routedApp());

      expect(
        tester.getSemantics(find.bySemanticsLabel('닉네임 변경')),
        matchesSemantics(
          label: '닉네임 변경',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: false,
          isFocusable: false,
        ),
      );
      // 연필 배지의 접근성 노드는 카드와 따로 남는다.
      expect(find.bySemanticsLabel('프로필 사진 변경'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('닉네임 변경'));
      await tester.pumpAndSettle();
      expect(find.byType(NicknameChangeScreen), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('withdraw button opens dialog', (tester) async {
    await _pumpMyPage(tester, MyPageHarness());

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴할까?'), findsOneWidget);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpMyPage(tester, MyPageHarness());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('developer mode easter egg', () {
    const serviceSectionTitle = '서비스 (앱정보 v0.15.0)';

    testWidgets('turns on after seven consecutive taps on the section title', (
      tester,
    ) async {
      final harness = MyPageHarness();
      await _pumpMyPage(tester, harness);

      for (var tap = 0; tap < 7; tap++) {
        await tester.tap(find.text(serviceSectionTitle));
      }
      await tester.pump();

      expect(harness.container.read(developerModeControllerProvider), isTrue);
      expect(harness.developerModeStorage.storedEnabled, isTrue);
      expect(harness.container.read(toastControllerProvider), '개발자 모드가 켜졌습니다');
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('stays off after six taps', (tester) async {
      final harness = MyPageHarness();
      await _pumpMyPage(tester, harness);

      for (var tap = 0; tap < 6; tap++) {
        await tester.tap(find.text(serviceSectionTitle));
      }
      await tester.pump();

      expect(harness.container.read(developerModeControllerProvider), isFalse);
      expect(harness.developerModeStorage.writeCount, 0);
    });

    testWidgets('tells the user when developer mode is already on', (
      tester,
    ) async {
      final harness = MyPageHarness();
      await harness.container
          .read(developerModeControllerProvider.notifier)
          .enable();
      await _pumpMyPage(tester, harness);

      for (var tap = 0; tap < 7; tap++) {
        await tester.tap(find.text(serviceSectionTitle));
      }
      await tester.pump();

      expect(
        harness.container.read(toastControllerProvider),
        '이미 개발자 모드가 켜져 있습니다',
      );
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('responsive layout', () {
    for (final viewport in viewportCases) {
      testWidgets('has no exception at ${viewport.label}', (tester) async {
        final harness = MyPageHarness(
          fetchedMember: memberWithoutEmail.copyWith(
            nickname: '가' * 40,
            email: '${'a' * 60}@teeq.com',
          ),
        );
        await _pumpMyPage(tester, harness, viewport: viewport);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
