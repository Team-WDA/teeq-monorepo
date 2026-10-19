import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/button/neutral_filled_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/my_page/presentation/account_withdrawal_confirmation_dialog.dart';
import 'package:teeq/features/my_page/presentation/my_page_screen.dart';

import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

Future<void> _openDialog(
  WidgetTester tester,
  MyPageHarness harness, {
  ViewportCase viewport = _defaultViewport,
}) async {
  await pumpAtViewport(tester, viewport, harness.app(const MyPageScreen()));
  await tester.ensureVisible(find.text('회원 탈퇴'));
  await tester.tap(find.text('회원 탈퇴'));
  await tester.pumpAndSettle();
}

NeutralFilledButton _continueButton(WidgetTester tester) =>
    tester.widget<NeutralFilledButton>(find.byType(NeutralFilledButton));

PrimaryFilledButton _withdrawButton(WidgetTester tester) =>
    tester.widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton));

/// 다이얼로그 카드 바깥 스크림 위치를 탭한다.
Future<void> _tapScrim(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows title, description and both buttons', (tester) async {
    await _openDialog(tester, MyPageHarness());

    expect(find.text('정말 탈퇴할까?'), findsOneWidget);
    expect(
      find.text(
        '탈퇴하면 이 계정으로\n'
        'TeeQ를 이용할 수 없어.\n'
        '계속하려면 아래에서 탈퇴를 선택해줘.',
      ),
      findsOneWidget,
    );
    expect(find.text('계속 이용하기'), findsOneWidget);
    expect(find.text('탈퇴하기'), findsOneWidget);
  });

  testWidgets('continue button and scrim close only the dialog', (
    tester,
  ) async {
    final harness = MyPageHarness();
    await _openDialog(tester, harness);

    await tester.tap(find.text('계속 이용하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말 탈퇴할까?'), findsNothing);

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    await _tapScrim(tester);
    expect(find.text('정말 탈퇴할까?'), findsNothing);

    expect(harness.repository.deleteAccountCount, 0);
    expect(harness.repository.logoutCount, 0);
    expect(harness.currentMember, isNotNull);
  });

  testWidgets('withdraw success pops dialog before signing out and never '
      'calls logout', (tester) async {
    final harness = MyPageHarness();
    await _openDialog(tester, harness);
    harness.events.clear();

    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(harness.repository.deleteAccountCount, 1);
    expect(harness.repository.logoutCount, 0);
    expect(harness.events, ['pop', 'signOut']);
    expect(harness.currentMember, isNull);
    expect(find.text('정말 탈퇴할까?'), findsNothing);
    expect(harness.errorHandler.handledErrors, isEmpty);
  });

  testWidgets('withdraw failure reports error keeps dialog and re-enables '
      'buttons', (tester) async {
    final harness = MyPageHarness(
      deleteAccountError: DioException(requestOptions: RequestOptions()),
    );
    await _openDialog(tester, harness);

    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(find.text('정말 탈퇴할까?'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNotNull);
    expect(_withdrawButton(tester).onPressed, isNotNull);
    expect(harness.currentMember, isNotNull);
    expect(harness.events, isNot(contains('signOut')));
  });

  testWidgets('buttons are disabled while request is in progress', (
    tester,
  ) async {
    final gate = Completer<void>();
    final harness = MyPageHarness();
    await _openDialog(tester, harness);
    harness.repository.deleteAccountGate = gate;

    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();

    expect(_continueButton(tester).onPressed, isNull);
    expect(_withdrawButton(tester).onPressed, isNull);

    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    expect(harness.repository.deleteAccountCount, 1);

    // 요청 중 스크림 탭으로는 닫히지 않는다.
    await _tapScrim(tester);
    expect(find.text('정말 탈퇴할까?'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(harness.repository.deleteAccountCount, 1);
    expect(find.text('정말 탈퇴할까?'), findsNothing);
  });

  group('responsive layout', () {
    for (final viewport in viewportCases) {
      testWidgets('has no exception at ${viewport.label}', (tester) async {
        await _openDialog(tester, MyPageHarness(), viewport: viewport);

        expect(
          find.byType(AccountWithdrawalConfirmationDialog),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('dialog meets tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openDialog(tester, MyPageHarness());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
