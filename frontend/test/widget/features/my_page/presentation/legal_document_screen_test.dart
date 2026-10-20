import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/my_page/data/legal_document_loader.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';
import 'package:teeq/features/my_page/presentation/legal_document_screen.dart';

import '../../../../support/my_page_harness.dart';
import '../../../../support/viewport_cases.dart';

const _viewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

const _document = LegalDocument(
  version: 'v1',
  announcementDate: '2026.10.25',
  effectiveDate: '2026.10.25',
  articles: [
    LegalArticle(
      title: '제1조 테스트',
      blocks: [
        LegalParagraph(text: '① 첫 문단'),
        LegalTable(
          title: '계정',
          rows: [LegalTableRow(label: '목적', value: '가입')],
        ),
      ],
    ),
  ],
);

class _FakeLoader extends LegalDocumentLoader {
  _FakeLoader(this._result) : super(_NeverBundle());

  final Object _result;

  @override
  Future<LegalDocument> load(LegalDocumentType type) async {
    final result = _result;
    if (result is LegalDocument) {
      return result;
    }
    throw result;
  }
}

class _NeverBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

Future<RecordingErrorHandler> _pump(
  WidgetTester tester,
  Object loaderResult, {
  LegalDocumentType type = LegalDocumentType.serviceTerms,
}) async {
  final errorHandler = RecordingErrorHandler();
  await pumpAtViewport(
    tester,
    _viewport,
    ProviderScope(
      // 실패한 읽기가 재시도되지 않게 한다.
      retry: (retryCount, error) => null,
      overrides: [
        legalDocumentLoaderProvider.overrideWithValue(
          _FakeLoader(loaderResult),
        ),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: LegalDocumentScreen(type: type),
      ),
    ),
  );
  await tester.pump();
  return errorHandler;
}

void main() {
  testWidgets('renders title, meta, article title, paragraph and table', (
    tester,
  ) async {
    await _pump(tester, _document);

    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(
      find.text('버전: v1\n공고일: 2026.10.25\n시행일: 2026.10.25'),
      findsOneWidget,
    );
    expect(find.text('제1조 테스트'), findsOneWidget);
    expect(find.text('① 첫 문단'), findsOneWidget);
    for (final text in ['계정', '목적', '가입']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('uses the title of the requested document type', (tester) async {
    await _pump(tester, _document, type: LegalDocumentType.privacyPolicy);

    expect(find.text('개인정보 처리방침'), findsOneWidget);
  });

  testWidgets('hands asset load failure to the error handler as blocking', (
    tester,
  ) async {
    final errorHandler = await _pump(tester, Exception('missing asset'));

    expect(errorHandler.handledErrors, hasLength(1));
    expect(find.text('제1조 테스트'), findsNothing);
  });
}
