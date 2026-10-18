import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';

/// 캐릭터 결과 화면의 공통 골격. 제목·부제·말풍선·버튼은 위에, 배경 일러스트는 [decoration]이 아래에 깐다.
/// 일러스트가 화면 가장자리에서 잘리도록 화면 전체를 클립한다.
class CharacterResultScreenLayout extends StatelessWidget {
  const CharacterResultScreenLayout({
    super.key,
    required this.title,
    required this.description,
    required this.hintMessage,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.decoration,
  });

  final String title;
  final String description;
  final String hintMessage;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final Widget decoration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(child: decoration),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.horizontalMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: AppSpacing.space40 + AppSpacing.space20,
                    ),
                    ScreenTitleWithDescriptionHeading(
                      title: title,
                      description: description,
                    ),
                    const Spacer(),
                    Center(child: AccentOutlineHintTag(message: hintMessage)),
                    const SizedBox(height: AppSpacing.space16),
                    PrimaryFilledButton(
                      label: buttonLabel,
                      onPressed: onButtonPressed,
                    ),
                    const SizedBox(height: AppSpacing.space12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
