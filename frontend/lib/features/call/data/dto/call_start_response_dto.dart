import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';

part 'call_start_response_dto.g.dart';

/// 통화 시작 응답(`CallStartResponse`) 중 이 화면이 쓰는 필드만 받는다.
@JsonSerializable(createToJson: false)
class CallStartResponseDto {
  const CallStartResponseDto({
    required this.callSessionId,
    required this.maxDurationSeconds,
    required this.connection,
  });

  factory CallStartResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CallStartResponseDtoFromJson(json);

  final String callSessionId;
  final int maxDurationSeconds;

  /// LiveKit 접속 정보. 필요한 두 키만 꺼내 쓰므로 Map으로 받는다.
  final Map<String, dynamic> connection;

  /// `connection`에 문자열 `livekitUrl`·`token`이 없으면 [UnexpectedException]을 던진다.
  CallStartInfo toCallStartInfo() {
    final livekitUrl = connection['livekitUrl'];
    final token = connection['token'];
    if (livekitUrl is! String || token is! String) {
      throw const UnexpectedException('통화 시작 응답의 connection 형식이 올바르지 않음');
    }
    return CallStartInfo(
      callSessionId: callSessionId,
      maxDurationSeconds: maxDurationSeconds,
      serverUrl: livekitUrl,
      accessToken: token,
    );
  }
}
