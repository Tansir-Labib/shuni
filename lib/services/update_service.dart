import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Models a GitHub Release response
class AppRelease {
  final String version; // e.g., "1.1.1"
  final String changelog;
  final String downloadUrl; // URL for the .apk asset
  final String htmlUrl; // URL to the GitHub release page

  AppRelease({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.htmlUrl,
  });
}

/// # UpdateService
/// 
/// Handles checking for OTA updates from GitHub Releases, downloading APKs,
/// and triggering the Android package installer.
class UpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/Tansir-Labib/shuni/releases/latest';
  final Dio _dio = Dio();

  /// Checks if a newer version is available on GitHub.
  /// Returns an [AppRelease] if an update is found, otherwise null.
  Future<AppRelease?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.1.1"

      final release = await _fetchLatestRelease();
      if (release == null) return null;

      if (_isNewerVersion(currentVersion, release.version)) {
        return release;
      }
    } catch (_) {
      // Silently fail on network errors during background check
    }
    return null;
  }

  /// Fetches the latest release from GitHub regardless of whether the user
  /// is already on it. Used for the "View Changelog" feature.
  Future<AppRelease?> getLatestRelease() async {
    try {
      return await _fetchLatestRelease();
    } catch (_) {
      return null;
    }
  }

  /// Internal helper that fetches and parses the latest GitHub release.
  Future<AppRelease?> _fetchLatestRelease() async {
    final response = await http.get(Uri.parse(_repoUrl));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final latestTag = data['tag_name'] as String; // e.g., "v1.1.1"
    final latestVersion = latestTag.replaceAll('v', '');

    // Find the arm64 APK asset (preferred) or any APK
    final assets = data['assets'] as List;
    String? apkUrl;
    for (var asset in assets) {
      final name = asset['name'].toString();
      if (name.contains('arm64') && name.endsWith('.apk')) {
        apkUrl = asset['browser_download_url'];
        break;
      }
    }
    // Fallback: take any .apk if arm64 not found
    if (apkUrl == null) {
      for (var asset in assets) {
        if (asset['name'].toString().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'];
          break;
        }
      }
    }

    return AppRelease(
      version: latestVersion,
      changelog: data['body'] ?? 'No changelog provided.',
      downloadUrl: apkUrl ?? '',
      htmlUrl: data['html_url'] ?? '',
    );
  }

  /// Downloads the APK and triggers the Android installer.
  Future<void> downloadAndInstall(
      String url, Function(double progress) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/shuni_update.apk';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Trigger the Android package installer
      await OpenFilex.open(savePath);
    } catch (e) {
      throw Exception('Failed to download or install update: $e');
    }
  }

  /// Compares semantic version strings.
  /// Returns true if [latest] is newer than [current].
  bool _isNewerVersion(String current, String latest) {
    try {
      List<int> currParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      // Pad shorter list with zeros
      while (currParts.length < latestParts.length) {
        currParts.add(0);
      }
      while (latestParts.length < currParts.length) {
        latestParts.add(0);
      }

      for (int i = 0; i < currParts.length; i++) {
        if (latestParts[i] > currParts[i]) return true;
        if (latestParts[i] < currParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
