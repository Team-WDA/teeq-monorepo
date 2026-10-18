import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';

part 'home_summary_provider.g.dart';

/// 홈 요약. [memberId]는 회원별로 캐시를 나누는 키일 뿐 요청에는 쓰지 않는다.
@riverpod
Future<HomeSummary> homeSummary(Ref ref, String memberId) =>
    ref.watch(homeRepositoryProvider).fetchHome();
