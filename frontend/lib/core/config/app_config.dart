import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// 빌드 시 `--dart-define-from-file=config/<env>.json`으로 주입되는 환경값.
///
/// 이 클래스가 필요한 키의 유일한 정의 위치이다. 키를 추가하면
/// README 안내도 함께 갱신한다.
/// 클라이언트에 넣은 값은 앱에서 추출할 수 있으므로 서버 시크릿은 넣지 않는다.
/// 운영 값은 CI에서 `FRONTEND_CONFIG_JSON` 시크릿으로 `config/prod.json`을 만들어 주입한다.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
  );

  final String apiBaseUrl;

  /// 필수 키가 비어 있으면 앱 시작 시점에 즉시 실패시킨다.
  /// 배포 빌드에서 `FRONTEND_CONFIG_JSON`이 누락된 경우도 여기서 드러난다.
  void validate() {
    final missingKeys = <String>[if (apiBaseUrl.isEmpty) 'API_BASE_URL'];
    if (missingKeys.isEmpty) {
      return;
    }
    throw StateError(
      '필수 환경값이 없습니다: ${missingKeys.join(', ')}. '
      '--dart-define-from-file=config/dev.json 으로 실행하세요.',
    );
  }
}

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => AppConfig.current;
