import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/features/my_page/domain/profile_image_rule.dart';
import 'package:teeq/features/my_page/presentation/my_page_screen.dart';
import 'package:teeq/features/my_page/presentation/profile_image_sheet.dart';

import '../../../../support/fake_profile_image_picker.dart';
import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _viewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

const _uploadedImageUrl = 'https://cdn.teeq.test/profile/new.jpg';

/// 버튼으로 시트를 여는 화면에서 시트를 열어 둔다.
Future<void> _openSheet(WidgetTester tester, MyPageHarness harness) async {
  await pumpAtViewport(
    tester,
    _viewport,
    harness.app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showProfileImageSheet(context),
          child: const Text('시트 열기'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('시트 열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default state shows the title, guide text and two buttons', (
    tester,
  ) async {
    await _openSheet(tester, MyPageHarness());

    expect(find.text('프로필 사진 변경'), findsOneWidget);
    expect(find.textContaining('JPG·PNG 파일을 선택해줘.'), findsOneWidget);
    expect(find.text('사진 선택하기'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('cancelling the pick changes nothing', (tester) async {
    final picker = FakeProfileImagePicker();
    final harness = MyPageHarness(profileImagePicker: picker);
    await _openSheet(tester, harness);

    await tester.tap(find.text('사진 선택하기'));
    await tester.pumpAndSettle();

    expect(picker.pickCount, 1);
    expect(harness.repository.replacedProfileImage, isNull);
    expect(find.text('프로필 사진 변경'), findsOneWidget);
    expect(find.textContaining('올릴 수 있어.'), findsOneWidget);
  });

  testWidgets(
    'unsupported format shows a message under the guide and uploads nothing',
    (tester) async {
      final picker = FakeProfileImagePicker(
        result: FakeProfileImagePicker.imageOf(fileName: 'photo.gif'),
      );
      final harness = MyPageHarness(profileImagePicker: picker);
      await _openSheet(tester, harness);

      await tester.tap(find.text('사진 선택하기'));
      await tester.pumpAndSettle();

      expect(find.text('JPG, PNG 파일만 올릴 수 있어.'), findsOneWidget);
      expect(harness.repository.replacedProfileImage, isNull);
      expect(harness.errorHandler.handledErrors, isEmpty);
      expect(find.text('사진 선택하기'), findsOneWidget);
    },
  );

  testWidgets('file over 5MB shows a size message and uploads nothing', (
    tester,
  ) async {
    final picker = FakeProfileImagePicker(
      result: FakeProfileImagePicker.imageOf(
        byteLength: ProfileImageRule.maxByteLength + 1,
      ),
    );
    final harness = MyPageHarness(profileImagePicker: picker);
    await _openSheet(tester, harness);

    await tester.tap(find.text('사진 선택하기'));
    await tester.pumpAndSettle();

    expect(find.text('5MB 이하의 사진만 올릴 수 있어.'), findsOneWidget);
    expect(harness.repository.replacedProfileImage, isNull);
  });

  testWidgets(
    'while uploading the label changes and closing or re-picking is blocked',
    (tester) async {
      final picker = FakeProfileImagePicker(
        result: FakeProfileImagePicker.imageOf(),
      );
      final harness = MyPageHarness(profileImagePicker: picker);
      final gate = Completer<void>();
      harness.repository.replaceProfileImageGate = gate;
      await _openSheet(tester, harness);

      await tester.tap(find.text('사진 선택하기'));
      await tester.pump();
      await tester.pump();

      expect(find.text('사진을 올리고 있어'), findsOneWidget);
      expect(find.text('사진 선택하기'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('사진을 올리고 있어'));
      await tester.tap(find.text('취소'));
      await tester.tap(find.bySemanticsLabel('닫기'), warnIfMissed: false);
      await tester.pump();

      expect(picker.pickCount, 1);
      expect(find.text('프로필 사진 변경'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('success closes the sheet and updates the member photo url', (
    tester,
  ) async {
    final picker = FakeProfileImagePicker(
      result: FakeProfileImagePicker.imageOf(),
    );
    final harness = MyPageHarness(
      profileImagePicker: picker,
      fetchedMember: memberWithoutEmail.copyWith(
        profileImageUrl: _uploadedImageUrl,
      ),
    );
    await _openSheet(tester, harness);
    expect(harness.currentMember?.profileImageUrl, isNull);

    await tester.tap(find.text('사진 선택하기'));
    await tester.pumpAndSettle();

    expect(harness.repository.replacedProfileImage?.fileName, 'photo.jpg');
    expect(harness.currentMember?.profileImageUrl, _uploadedImageUrl);
    expect(find.text('프로필 사진 변경'), findsNothing);
  });

  testWidgets(
    'upload failure reports the error and keeps the sheet for another pick',
    (tester) async {
      final picker = FakeProfileImagePicker(
        result: FakeProfileImagePicker.imageOf(),
      );
      final harness = MyPageHarness(
        profileImagePicker: picker,
        replaceProfileImageError: const ApiException(
          errorCode: ErrorCode.profileImageInvalid,
          httpStatus: 400,
        ),
      );
      await _openSheet(tester, harness);

      await tester.tap(find.text('사진 선택하기'));
      await tester.pumpAndSettle();

      expect(harness.errorHandler.handledErrors, hasLength(1));
      expect(find.text('프로필 사진 변경'), findsOneWidget);
      expect(find.text('사진 선택하기'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('사진 선택하기'));
      await tester.pumpAndSettle();
      expect(picker.pickCount, 2);
    },
  );

  testWidgets('cancel and close buttons dismiss the sheet', (tester) async {
    final harness = MyPageHarness();
    await _openSheet(tester, harness);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('프로필 사진 변경'), findsNothing);

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('닫기'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('프로필 사진 변경'), findsNothing);
  });

  testWidgets('tapping the scrim does not dismiss the sheet', (tester) async {
    await _openSheet(tester, MyPageHarness());

    await tester.tapAt(const Offset(196, 40));
    await tester.pumpAndSettle();

    expect(find.text('프로필 사진 변경'), findsOneWidget);
  });

  testWidgets(
    'tapping the pencil badge on my page opens the sheet without going to nickname change',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = MyPageHarness();
      await pumpAtViewport(tester, _viewport, harness.routedApp());
      await tester.pumpAndSettle();
      expect(find.byType(MyPageScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('프로필 사진 변경'));
      await tester.pumpAndSettle();

      expect(find.text('사진 선택하기'), findsOneWidget);
      expect(find.text('닉네임 변경'), findsNothing);
      semantics.dispose();
    },
  );
}
