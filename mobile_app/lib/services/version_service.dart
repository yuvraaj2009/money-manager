import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

class VersionCheckResult {
  final bool updateRequired;
  final bool updateAvailable;
  final String latestVersion;
  final String currentVersion;
  final String updateUrl;
  final String apkUrl;
  final String message;

  const VersionCheckResult({
    required this.updateRequired,
    this.updateAvailable = false,
    required this.latestVersion,
    required this.currentVersion,
    this.updateUrl = '',
    this.apkUrl = '',
    this.message = '',
  });
}

class VersionService {
  VersionService(this._api);

  final ApiService _api;

  Future<VersionCheckResult> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final json = await _api.getJson('/version');
      final data = json as Map<String, dynamic>;
      final minAppVersion = data['min_app_version'] as String? ?? '1.0.0';
      final latestAppVersion = data['latest_app_version'] as String? ?? minAppVersion;
      final updateUrl = data['update_url'] as String? ?? '';
      final apkUrl = data['apk_url'] as String? ?? '';
      final message = data['message'] as String? ?? '';

      final updateRequired = _isOlderThan(currentVersion, minAppVersion);
      final updateAvailable =
          !updateRequired && _isOlderThan(currentVersion, latestAppVersion);

      return VersionCheckResult(
        updateRequired: updateRequired,
        updateAvailable: updateAvailable,
        latestVersion: latestAppVersion,
        currentVersion: currentVersion,
        updateUrl: updateUrl,
        apkUrl: apkUrl,
        message: message,
      );
    } catch (_) {
      // If we can't check, don't block the user
      return VersionCheckResult(
        updateRequired: false,
        latestVersion: currentVersion,
        currentVersion: currentVersion,
      );
    }
  }

  /// Returns true if [current] is strictly older than [required].
  bool _isOlderThan(String current, String required) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final requiredParts = required.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final c = (i < currentParts.length ? currentParts[i] : 0) ?? 0;
      final r = (i < requiredParts.length ? requiredParts[i] : 0) ?? 0;
      if (c < r) return true;
      if (c > r) return false;
    }
    return false;
  }
}
