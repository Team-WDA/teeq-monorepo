import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/app_update/domain/store_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

part 'url_store_launcher.g.dart';

/// `url_launcher`로 스토어를 외부 앱에서 여는 구현. 주소 형식 오류와 플랫폼 오류는 실패(false)로 돌려준다.
final class UrlStoreLauncher implements StoreLauncher {
  const UrlStoreLauncher();

  @override
  Future<bool> open(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
StoreLauncher storeLauncher(Ref ref) => const UrlStoreLauncher();
