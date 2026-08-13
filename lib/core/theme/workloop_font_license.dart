import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers licences for font assets bundled with Workloop.
///
/// Keeping this explicit ensures the Manrope licence is visible from
/// Flutter's standard licence page even though the font is bundled offline.
void registerWorkloopFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/Manrope-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope'], license);
  });
}
