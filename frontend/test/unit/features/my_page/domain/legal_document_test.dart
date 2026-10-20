import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';

void main() {
  test('parses meta, paragraph and table blocks in order', () {
    final document = LegalDocument.fromJson({
      'version': 'v1',
      'announcementDate': '2026.10.25',
      'effectiveDate': '2026.10.26',
      'articles': [
        {
          'title': '제1조 테스트',
          'blocks': [
            {'type': 'paragraph', 'text': '① 본문'},
            {
              'type': 'table',
              'title': '표 제목',
              'rows': [
                {'label': '목적', 'value': '값'},
              ],
            },
          ],
        },
      ],
    });

    expect(document.version, 'v1');
    expect(document.announcementDate, '2026.10.25');
    expect(document.effectiveDate, '2026.10.26');
    final blocks = document.articles.single.blocks;
    expect((blocks[0] as LegalParagraph).text, '① 본문');
    final table = blocks[1] as LegalTable;
    expect(table.title, '표 제목');
    expect(table.rows.single.label, '목적');
    expect(table.rows.single.value, '값');
  });

  test('rejects unknown block type', () {
    expect(
      () => LegalBlock.fromJson({'type': 'image'}),
      throwsA(isA<FormatException>()),
    );
  });
}
