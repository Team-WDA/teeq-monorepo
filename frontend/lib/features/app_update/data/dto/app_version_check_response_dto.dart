import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';

part 'app_version_check_response_dto.g.dart';

/// 앱 버전 확인 응답(`AppVersionCheckResponse`).
@JsonSerializable(createToJson: false)
class AppVersionCheckResponseDto {
  const AppVersionCheckResponseDto({
    required this.updateRequired,
    required this.minimumVersion,
    required this.storeUrl,
  });

  factory AppVersionCheckResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AppVersionCheckResponseDtoFromJson(json);

  final bool updateRequired;
  final String minimumVersion;
  final String storeUrl;

  /// 업데이트가 필요 없으면 null.
  AppUpdateRequirement? toRequirement() => updateRequired
      ? AppUpdateRequirement(minimumVersion: minimumVersion, storeUrl: storeUrl)
      : null;
}
