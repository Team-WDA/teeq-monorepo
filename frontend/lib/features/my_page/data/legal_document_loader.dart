import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';

part 'legal_document_loader.g.dart';

/// 앱 번들(`assets/legal/`)에서 약관 문서를 읽는다.
class LegalDocumentLoader {
  const LegalDocumentLoader(this._bundle);

  final AssetBundle _bundle;

  static String assetPathOf(LegalDocumentType type) => switch (type) {
    LegalDocumentType.serviceTerms => 'assets/legal/service_terms.json',
    LegalDocumentType.privacyPolicy => 'assets/legal/privacy_policy.json',
  };

  /// 자산이 없거나 형식이 틀리면 예외를 그대로 던진다(화면이 중앙 오류 처리로 넘긴다).
  Future<LegalDocument> load(LegalDocumentType type) async {
    final source = await _bundle.loadString(assetPathOf(type));
    return LegalDocument.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}

@Riverpod(keepAlive: true)
LegalDocumentLoader legalDocumentLoader(Ref ref) =>
    LegalDocumentLoader(rootBundle);

@riverpod
Future<LegalDocument> legalDocument(Ref ref, LegalDocumentType type) =>
    ref.watch(legalDocumentLoaderProvider).load(type);
