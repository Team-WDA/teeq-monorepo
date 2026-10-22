import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';

import '../../../support/fake_developer_mode_storage.dart';

ProviderContainer _container({
  bool initiallyEnabled = false,
  required FakeDeveloperModeStorage storage,
}) {
  final container = ProviderContainer(
    overrides: [
      initialDeveloperModeEnabledProvider.overrideWithValue(initiallyEnabled),
      developerModeStorageProvider.overrideWithValue(storage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts disabled by default', () {
    final container = _container(storage: FakeDeveloperModeStorage());

    expect(container.read(developerModeControllerProvider), isFalse);
  });

  test('starts enabled when the stored flag was read as enabled', () {
    final container = _container(
      initiallyEnabled: true,
      storage: FakeDeveloperModeStorage(storedEnabled: true),
    );

    expect(container.read(developerModeControllerProvider), isTrue);
  });

  test('enable switches on and persists the flag', () async {
    final storage = FakeDeveloperModeStorage();
    final container = _container(storage: storage);

    await container.read(developerModeControllerProvider.notifier).enable();

    expect(container.read(developerModeControllerProvider), isTrue);
    expect(storage.storedEnabled, isTrue);
  });

  test('disable switches off and persists the flag', () async {
    final storage = FakeDeveloperModeStorage(storedEnabled: true);
    final container = _container(initiallyEnabled: true, storage: storage);

    await container.read(developerModeControllerProvider.notifier).disable();

    expect(container.read(developerModeControllerProvider), isFalse);
    expect(storage.storedEnabled, isFalse);
  });

  test('keeps the switched state when persisting fails', () async {
    final storage = FakeDeveloperModeStorage(writeError: StateError('저장 실패'));
    final container = _container(storage: storage);

    await container.read(developerModeControllerProvider.notifier).enable();

    expect(storage.writeCount, 1);
    expect(container.read(developerModeControllerProvider), isTrue);
  });
}
