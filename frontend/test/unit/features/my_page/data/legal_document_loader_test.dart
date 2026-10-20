import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/my_page/data/legal_document_loader.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';

class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('Unable to load asset: $key'));
}

int _paragraphCount(LegalDocument document) => document.articles
    .expand((article) => article.blocks)
    .whereType<LegalParagraph>()
    .length;

int _tableCount(LegalArticle article) =>
    article.blocks.whereType<LegalTable>().length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final loader = LegalDocumentLoader(rootBundle);

  test('service terms asset matches the design', () async {
    final document = await loader.load(LegalDocumentType.serviceTerms);

    expect(document.version, 'v1');
    expect(document.announcementDate, '2026.10.25');
    expect(document.effectiveDate, '2026.10.25');
    expect(document.articles, hasLength(14));
    expect(document.articles.first.title, '제1조 목적과 운영자');
    expect(document.articles.last.title, '제14조 알파 테스터 참여 조건');
    expect(_paragraphCount(document), 47);
    // 시안 원문 그대로 보존한다(실제 달력에 없는 날짜처럼 보여도 고치지 않는다).
    final lastArticleBlocks = document.articles.last.blocks;
    expect(
      (lastArticleBlocks[1] as LegalParagraph).text,
      '② 미공개 초대 링크·접근 정보·테스트 자료는 사전 허락 없이 공개하지 않습니다. '
      '(의무 기간: 2026.10.20~2026.11.31)',
    );
  });

  test('privacy policy asset matches the design', () async {
    final document = await loader.load(LegalDocumentType.privacyPolicy);

    expect(document.version, 'v1');
    expect(document.announcementDate, '2026.10.25');
    expect(document.effectiveDate, '2026.10.25');
    expect(document.articles, hasLength(13));
    expect(document.articles.first.title, '제1조 개인정보처리자 및 적용 범위');
    expect(document.articles.last.title, '제13조 문의·권리구제 및 변경');
    expect(_paragraphCount(document), 45);
    // 제2조의 12개 카드와 제6조의 6개 카드는 각각 문단 사이 위치를 지킨다.
    final article2 = document.articles[1];
    expect(_tableCount(article2), 12);
    expect(article2.blocks.first, isA<LegalParagraph>());
    expect(article2.blocks[1], isA<LegalTable>());
    expect(article2.blocks[12], isA<LegalTable>());
    expect(article2.blocks[13], isA<LegalParagraph>());
    final article6 = document.articles[5];
    expect(_tableCount(article6), 6);
    expect(article6.blocks.first, isA<LegalTable>());
    expect(article6.blocks[6], isA<LegalParagraph>());
    // 카드 행 구조: 제2조는 목적·처리 항목·보유기간, 제6조는 위탁 업무·처리 항목.
    for (final table in article2.blocks.whereType<LegalTable>()) {
      expect(table.rows.map((row) => row.label), ['목적', '처리 항목', '보유기간']);
    }
    for (final table in article6.blocks.whereType<LegalTable>()) {
      expect(table.rows.map((row) => row.label), ['위탁 업무', '처리 항목']);
    }
    expect((article6.blocks.first as LegalTable).title, 'Soniox');
  });

  test('propagates asset load failure', () {
    final missing = LegalDocumentLoader(_EmptyAssetBundle());

    expect(
      missing.load(LegalDocumentType.serviceTerms),
      throwsA(isA<FlutterError>()),
    );
  });
}
