import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teeq/core/config/app_version_provider.dart';

void main() {
  test('returns version without build number', () async {
    PackageInfo.setMockInitialValues(
      appName: 'teeq',
      packageName: 'kr.co.teeq',
      version: '0.15.0',
      buildNumber: '19',
      buildSignature: '',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(appVersionProvider.future), '0.15.0');
  });
}
