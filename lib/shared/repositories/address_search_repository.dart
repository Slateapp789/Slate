import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final addressSearchRepositoryProvider = Provider<AddressSearchRepository>((
  ref,
) {
  return AddressSearchRepository(ref.watch(supabaseClientProvider));
});

class AddressPrediction {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final String unitLabel;
  final bool isPostcode;

  const AddressPrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.unitLabel = '',
    this.isPostcode = false,
  });

  factory AddressPrediction.fromMap(Map<String, dynamic> map) {
    return AddressPrediction(
      placeId: map['placeId'] as String? ?? '',
      primaryText: map['primaryText'] as String? ?? '',
      secondaryText: map['secondaryText'] as String? ?? '',
      fullText: map['fullText'] as String? ?? '',
      unitLabel: map['unitLabel'] as String? ?? '',
      isPostcode: map['isPostcode'] as bool? ?? false,
    );
  }
}

String preserveAddressUnit({
  required String formattedAddress,
  required String unitLabel,
}) {
  final address = formattedAddress.trim();
  final unit = unitLabel.trim();
  if (address.isEmpty || unit.isEmpty) return address;
  if (address.toLowerCase().contains(unit.toLowerCase())) return address;
  return '$unit, $address';
}

class ResolvedAddress {
  final String formattedAddress;
  final double? latitude;
  final double? longitude;

  const ResolvedAddress({
    required this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  factory ResolvedAddress.fromMap(Map<String, dynamic> map) {
    return ResolvedAddress(
      formattedAddress: map['formattedAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class AddressSearchRepository {
  final SupabaseClient _client;
  const AddressSearchRepository(this._client);

  Future<List<AddressPrediction>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final query = input.trim();
    if (query.length < 3) return const [];

    final response = await _client.functions.invoke(
      'places-address-search',
      body: {
        'action': 'autocomplete',
        'input': query,
        'sessionToken': sessionToken,
      },
    );
    final data = _responseMap(response.data);
    final predictions = data['predictions'];
    if (predictions is! List) return const [];
    return predictions
        .whereType<Map>()
        .map(
          (item) => AddressPrediction.fromMap(Map<String, dynamic>.from(item)),
        )
        .where(
          (prediction) =>
              prediction.placeId.isNotEmpty && prediction.fullText.isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<ResolvedAddress> resolve({
    required String placeId,
    required String sessionToken,
  }) async {
    final response = await _client.functions.invoke(
      'places-address-search',
      body: {
        'action': 'details',
        'placeId': placeId,
        'sessionToken': sessionToken,
      },
    );
    return ResolvedAddress.fromMap(_responseMap(response.data));
  }

  Map<String, dynamic> _responseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Unexpected address search response.');
  }
}
