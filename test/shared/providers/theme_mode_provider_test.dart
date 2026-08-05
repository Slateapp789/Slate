import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/providers/theme_mode_provider.dart';

class _MemoryThemeModeStore implements ThemeModeStore {
  String? value;
  bool failWrites = false;

  _MemoryThemeModeStore([this.value]);

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    this.value = value;
  }
}

void main() {
  test('appearance defaults to system when no value is stored', () async {
    final store = _MemoryThemeModeStore();
    final container = ProviderContainer(
      overrides: [themeModeStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(workloopAppearanceProvider.future),
      WorkloopAppearance.system,
    );
  });

  test('appearance restores and persists a selected mode', () async {
    final store = _MemoryThemeModeStore(WorkloopAppearance.dark.name);
    final container = ProviderContainer(
      overrides: [themeModeStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(workloopAppearanceProvider.future),
      WorkloopAppearance.dark,
    );

    await container
        .read(workloopAppearanceProvider.notifier)
        .setAppearance(WorkloopAppearance.light);

    expect(store.value, WorkloopAppearance.light.name);
    expect(
      container.read(workloopAppearanceProvider).value,
      WorkloopAppearance.light,
    );
  });

  test('failed persistence restores the previous appearance', () async {
    final store = _MemoryThemeModeStore(WorkloopAppearance.dark.name);
    final container = ProviderContainer(
      overrides: [themeModeStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(workloopAppearanceProvider.future);
    store.failWrites = true;

    await expectLater(
      container
          .read(workloopAppearanceProvider.notifier)
          .setAppearance(WorkloopAppearance.light),
      throwsStateError,
    );

    expect(
      container.read(workloopAppearanceProvider).value,
      WorkloopAppearance.dark,
    );
  });
}
