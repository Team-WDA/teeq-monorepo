import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 항목 문단 한 개.
class LegalParagraphText extends StatelessWidget {
  const LegalParagraphText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.body14RegularMultiline);
  }
}
