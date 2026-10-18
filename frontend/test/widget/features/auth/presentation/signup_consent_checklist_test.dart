import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/checkbox/rounded_square_checkbox.dart';
import 'package:teeq/features/auth/presentation/widgets/signup_consent_checklist.dart';

Future<(List<bool>, List<bool>)> _pump(
  WidgetTester tester, {
  required bool isServiceTermsAgreed,
  required bool isPrivacyPolicyAgreed,
}) async {
  final serviceTermsChanges = <bool>[];
  final privacyPolicyChanges = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SignupConsentChecklist(
          isServiceTermsAgreed: isServiceTermsAgreed,
          isPrivacyPolicyAgreed: isPrivacyPolicyAgreed,
          onServiceTermsChanged: serviceTermsChanges.add,
          onPrivacyPolicyChanged: privacyPolicyChanges.add,
        ),
      ),
    ),
  );
  return (serviceTermsChanges, privacyPolicyChanges);
}

bool _isAllAgreeChecked(WidgetTester tester) {
  return tester
      .widget<RoundedSquareCheckbox>(find.byType(RoundedSquareCheckbox).first)
      .isChecked;
}

void main() {
  testWidgets('둘 다 해제 상태에서 전체 동의를 탭하면 두 콜백이 true로 불린다', (tester) async {
    final (service, privacy) = await _pump(
      tester,
      isServiceTermsAgreed: false,
      isPrivacyPolicyAgreed: false,
    );

    await tester.tap(find.text('전체 동의'));

    expect(service, [true]);
    expect(privacy, [true]);
  });

  testWidgets('둘 다 체크 상태에서 전체 동의를 탭하면 두 콜백이 false로 불린다', (tester) async {
    final (service, privacy) = await _pump(
      tester,
      isServiceTermsAgreed: true,
      isPrivacyPolicyAgreed: true,
    );

    expect(_isAllAgreeChecked(tester), isTrue);
    await tester.tap(find.text('전체 동의'));

    expect(service, [false]);
    expect(privacy, [false]);
  });

  testWidgets('한쪽만 체크면 전체 동의는 해제 상태이고 탭하면 둘 다 true가 된다', (tester) async {
    final (service, privacy) = await _pump(
      tester,
      isServiceTermsAgreed: true,
      isPrivacyPolicyAgreed: false,
    );

    expect(_isAllAgreeChecked(tester), isFalse);
    await tester.tap(find.text('전체 동의'));

    expect(service, [true]);
    expect(privacy, [true]);
  });

  testWidgets('서비스 이용약관 행을 탭하면 해당 콜백만 불린다', (tester) async {
    final (service, privacy) = await _pump(
      tester,
      isServiceTermsAgreed: false,
      isPrivacyPolicyAgreed: false,
    );

    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));

    expect(service, [true]);
    expect(privacy, isEmpty);
  });

  testWidgets('개인정보 행을 탭하면 해당 콜백만 불린다', (tester) async {
    final (service, privacy) = await _pump(
      tester,
      isServiceTermsAgreed: false,
      isPrivacyPolicyAgreed: true,
    );

    await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));

    expect(service, isEmpty);
    expect(privacy, [false]);
  });

  testWidgets('안내 문구를 보여 준다', (tester) async {
    await _pump(
      tester,
      isServiceTermsAgreed: false,
      isPrivacyPolicyAgreed: false,
    );

    expect(find.text('필수 항목에 모두 동의하면 다음으로 진행할 수 있어.'), findsOneWidget);
  });

  testWidgets('각 행은 체크 상태를 가진 하나의 버튼으로 노출된다', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      isServiceTermsAgreed: true,
      isPrivacyPolicyAgreed: false,
    );

    SemanticsNode node(String label) =>
        tester.getSemantics(find.bySemanticsLabel(label));
    final allAgree = node('전체 동의');
    final serviceTerms = node('[필수] 서비스 이용약관 동의');
    final privacyPolicy = node('[필수] 개인정보 수집·이용 동의');

    for (final row in [allAgree, serviceTerms, privacyPolicy]) {
      expect(row.getSemanticsData().flagsCollection.isButton, isTrue);
    }
    expect(
      allAgree.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    expect(
      serviceTerms.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    expect(
      privacyPolicy.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    handle.dispose();
  });
}
