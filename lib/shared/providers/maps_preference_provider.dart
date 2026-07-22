import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MapsAppPreference { askEveryTime, appleMaps, googleMaps }

extension MapsAppPreferenceLabel on MapsAppPreference {
  String get label => switch (this) {
    MapsAppPreference.askEveryTime => 'Ask every time',
    MapsAppPreference.appleMaps => 'Apple Maps',
    MapsAppPreference.googleMaps => 'Google Maps',
  };
}

final preferredMapsAppProvider =
    AsyncNotifierProvider<PreferredMapsAppNotifier, MapsAppPreference>(
      PreferredMapsAppNotifier.new,
    );

final mapsPreferenceStoreProvider = Provider<MapsPreferenceStore>(
  (_) => SharedPreferencesMapsPreferenceStore(),
);

abstract class MapsPreferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesMapsPreferenceStore implements MapsPreferenceStore {
  final _preferences = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class PreferredMapsAppNotifier extends AsyncNotifier<MapsAppPreference> {
  static const _storageKey = 'workloop.preferred_maps_app';

  @override
  Future<MapsAppPreference> build() async {
    final stored = await ref
        .read(mapsPreferenceStoreProvider)
        .read(_storageKey);
    return MapsAppPreference.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => MapsAppPreference.askEveryTime,
    );
  }

  Future<void> setPreference(MapsAppPreference preference) async {
    await ref
        .read(mapsPreferenceStoreProvider)
        .write(_storageKey, preference.name);
    state = AsyncData(preference);
  }
}
