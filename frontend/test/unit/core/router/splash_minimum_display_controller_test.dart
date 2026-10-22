import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';

void main() {
  testWidgets('생성 직후에는 false이고 1.5초가 지나면 true가 된다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(
      splashMinimumDisplayControllerProvider,
      (previous, next) {},
    );

    expect(container.read(splashMinimumDisplayControllerProvider), isFalse);

    await tester.pump(
      splashMinimumDisplayDuration - const Duration(milliseconds: 1),
    );
    expect(container.read(splashMinimumDisplayControllerProvider), isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(splashMinimumDisplayControllerProvider), isTrue);
  });

  testWidgets('타이머가 끝나기 전에 dispose해도 오류 없이 끝난다', (tester) async {
    final container = ProviderContainer();
    container.read(splashMinimumDisplayControllerProvider);

    container.dispose();
    await tester.pump(splashMinimumDisplayDuration);
  });
}
