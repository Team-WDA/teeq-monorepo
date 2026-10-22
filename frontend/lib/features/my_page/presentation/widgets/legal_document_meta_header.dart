import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';

/// 문서 맨 위의 버전·공고일·시행일 세 줄.
class LegalDocumentMetaHeader extends StatelessWidget {
  const LegalDocumentMetaHeader({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Text(
      '버전: ${document.version}\n'
      '공고일: ${document.announcementDate}\n'
      '시행일: ${document.effectiveDate}',
      style: AppTextStyles.caption12RegularMultiline,
    );
  }
}
