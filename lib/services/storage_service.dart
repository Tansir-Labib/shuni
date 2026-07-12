import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// # StorageService
/// 
/// Manages physical files on the device filesystem under package-specific directories.
/// 
/// ## Folder Structure
/// - `/storage/emulated/0/Android/data/com.shuni.app/files/recordings/` : Where Opus compressed `.ogg` recordings live.
/// 
/// ## Learning Note
/// By writing files to package-specific external storage (`getExternalStorageDirectory`),
/// we do not require any runtime storage permissions on Android 11+ (API 30+), eliminating
/// the need for MANAGE_EXTERNAL_STORAGE.
class StorageService {
  StorageService._(); // Private constructor

  static String? _recordingsDirPath;

  /// Returns the package-specific external directory path where recordings are stored.
  /// Does not require runtime permissions on API 19+.
  static Future<String> get recordingsDirPath async {
    if (_recordingsDirPath != null) return _recordingsDirPath!;
    final Directory? extDir = await getExternalStorageDirectory();
    _recordingsDirPath = '${extDir!.path}/recordings';
    return _recordingsDirPath!;
  }

  /// Ensures that all required directories exist on the filesystem.
  static Future<void> initializeDirectories() async {
    final String path = await recordingsDirPath;
    final Directory recDir = Directory(path);
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }
  }

  /// Deletes a physical file at [path].
  static Future<bool> deleteFile(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Log or handle error
      return false;
    }
  }

  /// Lists all recorded files in the recording directory.
  static Future<List<File>> listRecordings() async {
    await initializeDirectories();
    final String path = await recordingsDirPath;
    final Directory recDir = Directory(path);
    
    try {
      final List<FileSystemEntity> entities = await recDir.list(recursive: false).toList();
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.ogg'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Exports/shares a recording file using the native share popup.
  static Future<void> shareRecording(String path, String subject) async {
    final File file = File(path);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(path)],
        subject: subject,
      );
    }
  }

  /// Gets the total size of all files in the recordings directory in bytes.
  static Future<int> getRecordingsDirectorySize() async {
    final String path = await recordingsDirPath;
    final Directory recDir = Directory(path);
    if (!await recDir.exists()) return 0;

    int totalSize = 0;
    try {
      await for (final FileSystemEntity entity in recDir.list(recursive: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (_) {
      // Fail silently
    }
    return totalSize;
  }
}
