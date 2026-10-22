import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 조 제목(예: 제1조 목적과 운영자).
class LegalArticleTitle extends StatelessWidget {
  const LegalArticleTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.body16BoldMultiline);
  }
}
