import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/my_page/presentation/nickname_change_screen.dart';

import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

Future<void> _openNicknameChange(
  WidgetTester tester,
  MyPageHarness harness,
) async {
  await pumpAtViewport(tester, _defaultViewport, harness.routedApp());
  await tester.tap(find.text('소연'));
  await tester.pumpAndSettle();
}

Future<void> _enterNickname(WidgetTester tester, String nickname) async {
  await tester.enterText(find.byType(TextField), nickname);
  await tester.pump();
}

bool _isSaveEnabled(WidgetTester tester) =>
    tester
        .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
        .onPressed !=
    null;

void main() {
  testWidgets('profile card tap opens nickname change screen', (tester) async {
    await _openNicknameChange(tester, MyPageHarness());

    expect(find.byType(NicknameChangeScreen), findsOneWidget);
    expect(find.text('닉네임 변경'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('· 한글 2~10자로 입력해줘.'), findsOneWidget);
    expect(find.text('· 영문·숫자·특수문자·공백은 사용할 수 없어.'), findsOneWidget);
    expect(_isSaveEnabled(tester), isFalse);
  });

  testWidgets('save is enabled only for a valid nickname', (tester) async {
    await _openNicknameChange(tester, MyPageHarness());

    await _enterNickname(tester, '새닉네임');
    expect(_isSaveEnabled(tester), isTrue);
    expect(find.text('4/10'), findsOneWidget);

    // 현재 닉네임과 같으면 비활성이다.
    await _enterNickname(tester, '소연');
    expect(_isSaveEnabled(tester), isFalse);
  });

  testWidgets('shows an error message for each rule violation', (tester) async {
    await _openNicknameChange(tester, MyPageHarness());

    await _enterNickname(tester, '가');
    expect(find.text('2자 이상으로 입력해줘'), findsOneWidget);
    expect(_isSaveEnabled(tester), isFalse);

    await _enterNickname(tester, '가나다라마바사아자차카');
    expect(find.text('10자 이하로 입력해줘'), findsOneWidget);
    expect(find.text('11/10'), findsOneWidget);
    expect(_isSaveEnabled(tester), isFalse);

    await _enterNickname(tester, '가나 다');
    expect(find.text('한글만 입력할 수 있어. 영문, 숫자, 특수문자, 공백은 빼줘.'), findsOneWidget);
    expect(_isSaveEnabled(tester), isFalse);
  });

  testWidgets('does not flag a jamo that the IME is still composing', (
    tester,
  ) async {
    const characterError = '한글만 입력할 수 있어. 영문, 숫자, 특수문자, 공백은 빼줘.';
    await _openNicknameChange(tester, MyPageHarness());
    await _enterNickname(tester, '가나');

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '가나ㅅ',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 2, end: 3),
      ),
    );
    await tester.pump();
    expect(find.text(characterError), findsNothing);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '가나ㅅ',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(find.text(characterError), findsOneWidget);
  });

  testWidgets('clear button empties the input', (tester) async {
    await _openNicknameChange(tester, MyPageHarness());
    await _enterNickname(tester, '새닉네임');

    await tester.tap(find.bySemanticsLabel('입력 지우기'));
    await tester.pump();

    expect(find.text('0/10'), findsOneWidget);
    expect(_isSaveEnabled(tester), isFalse);
  });

  testWidgets('duplicate nickname shows inline error and stays', (
    tester,
  ) async {
    final harness = MyPageHarness(
      changeNicknameError: const ApiException(
        errorCode: ErrorCode.duplicateNickname,
        httpStatus: 409,
      ),
    );
    await _openNicknameChange(tester, harness);

    await _enterNickname(tester, '새닉네임');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
    expect(find.byType(NicknameChangeScreen), findsOneWidget);
    expect(harness.errorHandler.handledErrors, isEmpty);

    // 다시 입력하면 오류 문구가 사라진다.
    await _enterNickname(tester, '새닉네임둘');
    expect(find.text('이미 사용 중인 닉네임이에요.'), findsNothing);
  });

  testWidgets('other errors go to the central error handler', (tester) async {
    final harness = MyPageHarness(changeNicknameError: Exception('offline'));
    await _openNicknameChange(tester, harness);

    await _enterNickname(tester, '새닉네임');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(harness.errorHandler.handledErrors, hasLength(1));
    expect(find.byType(NicknameChangeScreen), findsOneWidget);
    expect(_isSaveEnabled(tester), isTrue);
  });

  testWidgets('successful save pops and updates my page nickname', (
    tester,
  ) async {
    final harness = MyPageHarness();
    await _openNicknameChange(tester, harness);

    await _enterNickname(tester, '새닉네임');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(harness.repository.changedNickname, '새닉네임');
    expect(harness.events, contains('pop'));
    expect(find.byType(NicknameChangeScreen), findsNothing);
    expect(find.text('새닉네임'), findsOneWidget);
    expect(harness.currentMember?.nickname, '새닉네임');
  });

  testWidgets('repeated taps while saving send one request', (tester) async {
    final harness = MyPageHarness();
    final gate = Completer<void>();
    harness.repository.changeNicknameGate = gate;
    await _openNicknameChange(tester, harness);

    await _enterNickname(tester, '새닉네임');
    await tester.tap(find.text('저장하기'));
    await tester.pump();
    await tester.tap(find.text('저장하기'), warnIfMissed: false);
    await tester.pump();

    expect(_isSaveEnabled(tester), isFalse);
    expect(harness.repository.changeNicknameCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('back button pops without saving', (tester) async {
    final harness = MyPageHarness();
    await _openNicknameChange(tester, harness);

    await tester.tap(find.bySemanticsLabel('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.byType(NicknameChangeScreen), findsNothing);
    expect(harness.repository.changedNickname, isNull);
  });
}
