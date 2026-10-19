import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

/// 설치된 앱의 버전 이름(빌드 번호 제외). 마이 화면의 서비스 섹션 제목에 쓴다.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
