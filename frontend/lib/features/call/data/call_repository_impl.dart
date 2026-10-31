import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/call/data/dto/call_limit_status_response_dto.dart';
import 'package:teeq/features/call/data/dto/call_start_response_dto.dart';
import 'package:teeq/features/call/domain/call_limit_status.dart';
import 'package:teeq/features/call/domain/call_repository.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';

part 'call_repository_impl.g.dart';

/// [Dio]로 통화 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<CallStartInfo> startCall() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/calls');
    try {
      return CallStartResponseDto.fromJson(response.data!).toCallStartInfo();
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw UnexpectedException(error);
    }
  }

  @override
  Future<CallLimitStatus> fetchTodayLimitStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/call-limits/today',
    );
    return CallLimitStatusResponseDto.fromJson(response.data!)
        .toCallLimitStatus();
  }
}

@Riverpod(keepAlive: true)
CallRepository callRepository(Ref ref) =>
    CallRepositoryImpl(ref.watch(dioProvider));
