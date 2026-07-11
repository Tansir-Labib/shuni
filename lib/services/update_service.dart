import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Models a GitHub Release response
class AppRelease {
  final String version; // e.g., "v1.0.1"
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
  static const String _repoUrl = 'https://api.github.com/repos/Tansir-Labib/shuni/releases/latest';
  final Dio _dio = Dio();

  /// Checks if a newer version is available on GitHub.
  /// Returns an [AppRelease] if an update is found, otherwise null.
  Future<AppRelease?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.0.1"

      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestTag = data['tag_name'] as String; // e.g., "v1.0.1"
        final latestVersion = latestTag.replaceAll('v', '');
        
        // Very basic string comparison for versions (works for 1.0.1 vs 1.0.2)
        // If current is 1.0.1 and latest is 1.0.2, it will trigger.
        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Find the APK asset
          final assets = data['assets'] as List;
          String? apkUrl;
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }

          if (apkUrl != null) {
            return AppRelease(
              version: latestVersion,
              changelog: data['body'] ?? 'No changelog provided.',
              downloadUrl: apkUrl,
              htmlUrl: data['html_url'],
            );
          }
        }
      }
    } catch (e) {
      // Silently fail on network errors during background check
    }
    return null;
  }

  /// Downloads the APK and triggers the Android installer.
  Future<void> downloadAndInstall(
      String url, Function(double progress) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

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
      throw Exception('Failed to download or install update.');
    }
  }

  /// Compares semantic version strings
  bool _isNewerVersion(String current, String latest) {
    List<int> currParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currParts.length && i < latestParts.length; i++) {
      if (latestParts[i] > currParts[i]) return true;
      if (latestParts[i] < currParts[i]) return false;
    }
    return latestParts.length > currParts.length;
  }
}
