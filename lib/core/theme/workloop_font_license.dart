import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers licences for font assets bundled with Workloop.
///
/// Keeping this explicit ensures the Instrument Sans licence is visible from
/// Flutter's standard licence page even though the font is bundled offline.
void registerWorkloopFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/InstrumentSans-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Instrument Sans'], license);
  });
}
