/// 앱에서 보여 주는 약관 문서의 종류.
enum LegalDocumentType {
  serviceTerms('서비스 이용약관'),
  privacyPolicy('개인정보 처리방침');

  const LegalDocumentType(this.title);

  final String title;
}

/// 약관 문서 한 건. 번들 자산 JSON을 [LegalDocument.fromJson]으로 읽는다.
final class LegalDocument {
  const LegalDocument({
    required this.version,
    required this.announcementDate,
    required this.effectiveDate,
    required this.articles,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    version: json['version'] as String,
    announcementDate: json['announcementDate'] as String,
    effectiveDate: json['effectiveDate'] as String,
    articles: [
      for (final article in json['articles'] as List<dynamic>)
        LegalArticle.fromJson(article as Map<String, dynamic>),
    ],
  );

  final String version;
  final String announcementDate;
  final String effectiveDate;
  final List<LegalArticle> articles;
}

/// 조. 제목과 순서가 있는 블록(문단·표)으로 이루어진다.
final class LegalArticle {
  const LegalArticle({required this.title, required this.blocks});

  factory LegalArticle.fromJson(Map<String, dynamic> json) => LegalArticle(
    title: json['title'] as String,
    blocks: [
      for (final block in json['blocks'] as List<dynamic>)
        LegalBlock.fromJson(block as Map<String, dynamic>),
    ],
  );

  final String title;
  final List<LegalBlock> blocks;
}

/// 조 안의 본문 단위.
sealed class LegalBlock {
  const LegalBlock();

  /// `type`이 알려진 값이 아니면 [FormatException]을 던진다.
  factory LegalBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'paragraph' => LegalParagraph(text: json['text'] as String),
      'table' => LegalTable.fromJson(json),
      _ => throw FormatException('알 수 없는 약관 블록 유형: $type'),
    };
  }
}

/// 항목 문단. 번호(①)를 포함한 원문 그대로다.
final class LegalParagraph extends LegalBlock {
  const LegalParagraph({required this.text});

  final String text;
}

/// 제목과 `라벨: 값` 행으로 이루어진 표(회색 카드).
final class LegalTable extends LegalBlock {
  const LegalTable({required this.title, required this.rows});

  factory LegalTable.fromJson(Map<String, dynamic> json) => LegalTable(
    title: json['title'] as String,
    rows: [
      for (final row in json['rows'] as List<dynamic>)
        LegalTableRow(
          label: (row as Map<String, dynamic>)['label'] as String,
          value: row['value'] as String,
        ),
    ],
  );

  final String title;
  final List<LegalTableRow> rows;
}

final class LegalTableRow {
  const LegalTableRow({required this.label, required this.value});

  final String label;
  final String value;
}
