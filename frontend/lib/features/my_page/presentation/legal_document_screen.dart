import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/my_page/data/legal_document_loader.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';
import 'package:teeq/features/my_page/presentation/widgets/legal_article_title.dart';
import 'package:teeq/features/my_page/presentation/widgets/back_button_with_centered_title_header.dart';
import 'package:teeq/features/my_page/presentation/widgets/legal_document_meta_header.dart';
import 'package:teeq/features/my_page/presentation/widgets/legal_paragraph_text.dart';
import 'package:teeq/features/my_page/presentation/widgets/legal_table_card.dart';

/// 서비스 이용약관·개인정보 처리방침을 보여 주는 스크롤 화면. 종류는 [type]으로 고른다.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 자산을 못 읽으면 되돌아갈 곳이 없는 읽기 실패이므로 오류 페이지로 넘긴다.
    ref.listen(legalDocumentProvider(type), (previous, next) {
      if (next case AsyncError(:final error)) {
        ref.read(errorHandlerProvider).handle(error, blocking: true);
      }
    });
    final document = ref.watch(legalDocumentProvider(type)).value;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackButtonWithCenteredTitleHeader(
              title: type.title,
              onBackPressed: () => context.pop(),
            ),
            if (document != null)
              Expanded(child: _LegalDocumentBody(document: document)),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentBody extends StatelessWidget {
  const _LegalDocumentBody({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      LegalDocumentMetaHeader(document: document),
      for (final article in document.articles) ...[
        LegalArticleTitle(title: article.title),
        for (final block in article.blocks)
          switch (block) {
            LegalParagraph() => LegalParagraphText(text: block.text),
            LegalTable() => LegalTableCard(table: block),
          },
      ],
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.horizontalMargin,
        AppSpacing.space12,
        AppLayout.horizontalMargin,
        AppSpacing.space24,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.space18),
    );
  }
}
