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
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/app-versions/check',
      queryParameters: {
        'platform': platform.serverName,
        'appVersion': appVersion,
      },
      options: Options(
        connectTimeout: appVersionCheckTimeout,
        receiveTimeout: appVersionCheckTimeout,
      ),
    );
    return AppVersionCheckResponseDto.fromJson(response.data!).toRequirement();
  }
}

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) =>
    AppUpdateRepositoryImpl(ref.watch(dioProvider));
