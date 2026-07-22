import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workloop/shared/providers/theme_mode_provider.dart';

class _MemoryThemeModeStore implements ThemeModeStore {
  String? value;

  _MemoryThemeModeStore([this.value]);

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
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
}
