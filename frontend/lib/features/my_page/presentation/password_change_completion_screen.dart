import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';

/// 비밀번호 변경에 성공한 뒤 보여 주는 완료 화면. 폼을 대체하므로 닫으면 마이로 돌아간다.
class PasswordChangeCompletionScreen extends StatelessWidget {
  const PasswordChangeCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomActionScreenLayout(
      onBackPressed: context.pop,
      content: const ScreenTitleWithDescriptionHeading(
        title: '비밀번호를 변경했어!',
        description: '이제 새 비밀번호로 로그인할 수 있어.',
      ),
      bottomAction: PrimaryFilledButton(label: '확인', onPressed: context.pop),
    );
  }
}
