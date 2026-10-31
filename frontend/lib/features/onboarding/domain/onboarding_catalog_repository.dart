import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';

/// 온보딩 질문 구조 API.
abstract interface class OnboardingCatalogRepository {
  /// 서버 질문 구조를 받아 문구와 합친 카탈로그를 돌려준다.
  Future<OnboardingCatalog> fetchCatalog();
}
