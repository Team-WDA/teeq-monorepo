import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/app_update/data/dto/app_version_check_response_dto.dart';
import 'package:teeq/features/app_update/domain/app_platform.dart';
import 'package:teeq/features/app_update/domain/app_update_repository.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';

part 'app_update_repository_impl.g.dart';

/// 버전 검사가 스플래시를 오래 붙잡지 않도록 이 요청에만 거는 짧은 타임아웃.
const appVersionCheckTimeout = Duration(seconds: 5);

/// [Dio]로 앱 버전 확인 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<AppUpdateRequirement?> checkRequirement({
    required AppPlatform platform,
    required String appVersion,
  }) async {
    // 연결·수신 타임아웃은 단계별 제한이라 합계를 막지 못하므로 요청 전체에도 마감을 건다.
    // 마감을 넘기면 TimeoutException이 나며, 호출한 쪽이 통과(fail-open)로 처리한다.
    final response = await _dio
        .get<Map<String, dynamic>>(
          '/api/app-versions/check',
          queryParameters: {
            'platform': platform.serverName,
            'appVersion': appVersion,
          },
          options: Options(
            connectTimeout: appVersionCheckTimeout,
            receiveTimeout: appVersionCheckTimeout,
          ),
        )
        .timeout(appVersionCheckTimeout);
    return AppVersionCheckResponseDto.fromJson(response.data!).toRequirement();
  }
}

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) =>
    AppUpdateRepositoryImpl(ref.watch(dioProvider));
