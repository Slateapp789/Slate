import 'package:package_info_plus/package_info_plus.dart';

abstract final class WorkloopAppInfo {
  static const name = 'Workloop';
  static String version = '1.0.0';
  static String buildNumber = '1';
  static String get versionLabel => '$version ($buildNumber)';
  static const supportEmail = 'support@workloop.app';
  static const privacyUrl = 'https://workloop.app/privacy.html';
  static const termsUrl = 'https://workloop.app/terms.html';
  static const accountDeletionUrl = 'https://workloop.app/delete-account.html';

  static Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platformVersion = packageInfo.version.trim();
      final platformBuildNumber = packageInfo.buildNumber.trim();
      if (platformVersion.isNotEmpty) version = platformVersion;
      if (platformBuildNumber.isNotEmpty) {
        buildNumber = platformBuildNumber;
      }
    } catch (_) {
      // Keep the pubspec fallbacks above if platform metadata is unavailable.
      // App launch and support access must not fail because diagnostics did.
    }
  }
}
