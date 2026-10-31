import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';

part 'onboarding_catalog_provider.g.dart';

/// 온보딩 질문 카탈로그. 진입점(소개 화면, 수정 확인 팝업)이 불러 둔 뒤 흐름 전체가 공유한다.
/// 실패는 캐시되므로 진입점이 오류를 처리한 뒤 invalidate해서 다시 시도하게 한다.
@Riverpod(keepAlive: true)
Future<OnboardingCatalog> onboardingCatalog(Ref ref) =>
    ref.watch(onboardingCatalogRepositoryProvider).fetchCatalog();
