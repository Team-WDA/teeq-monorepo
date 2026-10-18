import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/home/data/dto/home_response_dto.dart';
import 'package:teeq/features/home/domain/home_repository.dart';
import 'package:teeq/features/home/domain/home_summary.dart';

part 'home_repository_impl.g.dart';

/// [Dio]로 홈 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<HomeSummary> fetchHome() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/home');
    return HomeResponseDto.fromJson(response.data!).toHomeSummary();
  }
}

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) =>
    HomeRepositoryImpl(ref.watch(dioProvider));
