import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        toastDisplayDurationProvider.overrideWithValue(
          const Duration(seconds: 3),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(toastControllerProvider, (previous, next) {});
  });

  String? current() => container.read(toastControllerProvider);
  void show(String message) =>
      container.read(toastControllerProvider.notifier).show(message);

  testWidgets('3초 뒤 자동으로 사라진다', (tester) async {
    show('안녕');
    expect(current(), '안녕');

    await tester.pump(const Duration(milliseconds: 2900));
    expect(current(), '안녕');

    await tester.pump(const Duration(milliseconds: 200));
    expect(current(), isNull);
  });

  testWidgets('같은 문구는 무시하고 타이머를 다시 시작하지 않는다', (tester) async {
    show('안녕');
    await tester.pump(const Duration(seconds: 2));
    show('안녕');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(current(), isNull);
  });

  testWidgets('다른 문구는 교체하고 타이머를 다시 시작한다', (tester) async {
    show('첫째');
    await tester.pump(const Duration(seconds: 2));
    show('둘째');
    expect(current(), '둘째');

    await tester.pump(const Duration(seconds: 2));
    expect(current(), '둘째');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(current(), isNull);
  });
}
