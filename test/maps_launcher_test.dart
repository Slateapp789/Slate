import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/providers/maps_preference_provider.dart';
import 'package:workloop/shared/utils/maps_launcher.dart';

class _MemoryMapsPreferenceStore implements MapsPreferenceStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  const address = '57 Tanfield Road, Huddersfield, HD1 5HD, UK';

  test('Google Maps directions URL contains the saved destination', () {
    final uri = mapsDirectionsUri(MapsAppPreference.googleMaps, address);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], address);
    expect(uri.queryParameters['travelmode'], 'driving');
  });

  test('Apple Maps directions URL contains the saved destination', () {
    final uri = mapsDirectionsUri(MapsAppPreference.appleMaps, address);

    expect(uri.host, 'maps.apple.com');
    expect(uri.queryParameters['daddr'], address);
    expect(uri.queryParameters['dirflg'], 'd');
  });

  test('a concrete maps app is required before building directions', () {
    expect(
      () => mapsDirectionsUri(MapsAppPreference.askEveryTime, address),
      throwsArgumentError,
    );
  });

  test('the selected default maps app persists on the device', () async {
    final store = _MemoryMapsPreferenceStore();
    final container = ProviderContainer(
      overrides: [mapsPreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(preferredMapsAppProvider.future),
      MapsAppPreference.askEveryTime,
    );
    await container
        .read(preferredMapsAppProvider.notifier)
        .setPreference(MapsAppPreference.googleMaps);

    expect(
      container.read(preferredMapsAppProvider).value,
      MapsAppPreference.googleMaps,
    );
    expect(store.values.values.single, MapsAppPreference.googleMaps.name);
  });
}
