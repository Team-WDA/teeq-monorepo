import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';
import 'package:teeq/features/my_page/presentation/password_change_completion_screen.dart';
import 'package:teeq/features/my_page/presentation/password_change_screen.dart';

import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

Future<void> _openPasswordChange(
  WidgetTester tester,
  MyPageHarness harness,
) async {
  await pumpAtViewport(tester, _defaultViewport, harness.routedApp());
  await tester.tap(find.text('비밀번호 변경'));
  await tester.pumpAndSettle();
}

Future<void> _enterPasswords(
  WidgetTester tester, {
  String current = 'oldpass1',
  String next = 'newpass12',
  String confirmation = 'newpass12',
}) async {
  await tester.enterText(find.byType(TextField).at(0), current);
  await tester.enterText(find.byType(TextField).at(1), next);
  await tester.enterText(find.byType(TextField).at(2), confirmation);
  await tester.pump();
}

bool _isSubmitEnabled(WidgetTester tester) =>
    tester
        .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
        .onPressed !=
    null;

void main() {
  testWidgets('password row tap opens the form with a disabled button', (
    tester,
  ) async {
    await _openPasswordChange(tester, MyPageHarness(member: emailMember));

    expect(find.byType(PasswordChangeScreen), findsOneWidget);
    expect(find.text('현재 비밀번호'), findsOneWidget);
    expect(_isSubmitEnabled(tester), isFalse);
  });

  testWidgets('submit is enabled only when all fields are valid and match', (
    tester,
  ) async {
    await _openPasswordChange(tester, MyPageHarness(member: emailMember));

    await _enterPasswords(tester, current: '');
    expect(_isSubmitEnabled(tester), isFalse);

    await _enterPasswords(tester, next: 'short1', confirmation: 'short1');
    expect(_isSubmitEnabled(tester), isFalse);

    await _enterPasswords(tester, confirmation: 'different12');
    expect(_isSubmitEnabled(tester), isFalse);

    await _enterPasswords(tester);
    expect(_isSubmitEnabled(tester), isTrue);

    // 새 비밀번호가 현재와 같아도 막지 않는다.
    await _enterPasswords(tester, current: 'newpass12');
    expect(_isSubmitEnabled(tester), isTrue);
  });

  testWidgets('shows the guide until the new password is typed and swaps it '
      'for the error', (tester) async {
    await _openPasswordChange(tester, MyPageHarness(member: emailMember));
    const guide = '8자 이상, 영문과 숫자를 함께 입력해줘';
    expect(find.text(guide), findsOneWidget);
    expect(find.text('현재 비밀번호를 입력해줘.'), findsOneWidget);
    expect(find.text('새 비밀번호를 입력해줘.'), findsOneWidget);
    expect(find.text('새 비밀번호를 한 번 더 입력해줘.'), findsOneWidget);

    await _enterPasswords(tester, next: 'abc1', confirmation: '');
    expect(find.text(guide), findsNothing);
    expect(find.text('비밀번호는 8자 이상으로 입력해줘'), findsOneWidget);

    await _enterPasswords(tester);
    expect(find.text(guide), findsNothing);
  });

  testWidgets('inputs are disabled while the request is in progress', (
    tester,
  ) async {
    final harness = MyPageHarness(member: emailMember);
    final gate = Completer<void>();
    harness.credentialProvider.changePasswordGate = gate;
    await _openPasswordChange(tester, harness);
    await _enterPasswords(tester);

    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pump();

    for (var index = 0; index < 3; index++) {
      expect(
        tester.widget<TextField>(find.byType(TextField).at(index)).enabled,
        isFalse,
      );
    }

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error message for each rule violation', (tester) async {
    await _openPasswordChange(tester, MyPageHarness(member: emailMember));

    await _enterPasswords(tester, next: 'abc1', confirmation: '');
    expect(find.text('비밀번호는 8자 이상으로 입력해줘'), findsOneWidget);

    await _enterPasswords(tester, next: 'abcdefgh', confirmation: '');
    expect(find.text('영문과 숫자를 함께 입력해줘'), findsOneWidget);

    await _enterPasswords(tester, confirmation: 'different12');
    expect(find.text('새 비밀번호가 일치하지 않아'), findsOneWidget);
  });

  testWidgets('invalid current password shows inline error and stays', (
    tester,
  ) async {
    final harness = MyPageHarness(
      member: emailMember,
      changePasswordError: const InvalidCurrentPasswordException(),
    );
    await _openPasswordChange(tester, harness);

    await _enterPasswords(tester);
    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pumpAndSettle();

    expect(find.text('현재 비밀번호가 일치하지 않아'), findsOneWidget);
    expect(find.byType(PasswordChangeScreen), findsOneWidget);
    expect(harness.errorHandler.handledErrors, isEmpty);
    // 불일치 오류가 떠 있는 동안에는 다시 보낼 수 없다.
    expect(_isSubmitEnabled(tester), isFalse);

    // 현재 비밀번호를 고치면 문구가 사라지고 다시 보낼 수 있다.
    await tester.enterText(find.byType(TextField).at(0), 'oldpass2');
    await tester.pump();
    expect(find.text('현재 비밀번호가 일치하지 않아'), findsNothing);
    expect(_isSubmitEnabled(tester), isTrue);
  });

  testWidgets('other errors go to the central error handler', (tester) async {
    final harness = MyPageHarness(
      member: emailMember,
      changePasswordError: Exception('offline'),
    );
    await _openPasswordChange(tester, harness);

    await _enterPasswords(tester);
    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(find.byType(PasswordChangeScreen), findsOneWidget);
    expect(_isSubmitEnabled(tester), isTrue);
  });

  testWidgets('success replaces the form with the completion screen', (
    tester,
  ) async {
    final harness = MyPageHarness(member: emailMember);
    await _openPasswordChange(tester, harness);

    await _enterPasswords(tester);
    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pumpAndSettle();

    expect(
      harness.credentialProvider.lastPasswordChange?.newPassword,
      'newpass12',
    );
    expect(
      harness.credentialProvider.lastPasswordChange?.currentPassword,
      'oldpass1',
    );
    expect(find.byType(PasswordChangeScreen), findsNothing);
    expect(find.byType(PasswordChangeCompletionScreen), findsOneWidget);
    expect(find.text('비밀번호를 변경했어!'), findsOneWidget);

    // 확인을 누르면 폼이 아니라 마이로 돌아간다.
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordChangeCompletionScreen), findsNothing);
    expect(find.byType(PasswordChangeScreen), findsNothing);
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('completion back button returns to my page', (tester) async {
    final harness = MyPageHarness(member: emailMember);
    await _openPasswordChange(tester, harness);
    await _enterPasswords(tester);
    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordChangeCompletionScreen), findsNothing);
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('repeated taps while submitting send one request', (
    tester,
  ) async {
    final harness = MyPageHarness(member: emailMember);
    final gate = Completer<void>();
    harness.credentialProvider.changePasswordGate = gate;
    await _openPasswordChange(tester, harness);

    await _enterPasswords(tester);
    await tester.tap(find.text('비밀번호 변경').last);
    await tester.pump();
    expect(
      tester
          .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
          .isLoading,
      isTrue,
    );
    expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryFilledButton), warnIfMissed: false);
    await tester.pump();

    expect(
      harness.credentialProvider.calls.where((c) => c == 'changeEmailPassword'),
      hasLength(1),
    );

    gate.complete();
    await tester.pumpAndSettle();
  });
}
