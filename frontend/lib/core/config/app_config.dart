import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// 빌드 시 `--dart-define-from-file=config/<env>.json`으로 주입되는 환경값.
///
/// 이 클래스가 필요한 키의 유일한 정의 위치이다. 키를 추가하면
/// `.claude/rules/70-secrets-and-env.md`의 키 목록과 README 안내도 함께 갱신한다.
/// 클라이언트에 넣은 값은 앱에서 추출할 수 있으므로 서버 시크릿은 넣지 않는다.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
  );

  final String apiBaseUrl;

  /// 필수 키가 비어 있으면 앱 시작 시점에 즉시 실패시킨다.
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
