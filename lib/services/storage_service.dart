import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';

/// # StorageService
/// 
/// Manages physical files on the device filesystem under the public `/Shuni/` directories.
/// 
/// ## Folder Structure
/// - `/storage/emulated/0/Shuni/recordings/` : Where Opus compressed `.ogg` recordings live.
/// - `/storage/emulated/0/Shuni/.shuni_db/` : Where the SQLite database file lives.
/// 
/// ## Learning Note
/// By writing files to `/storage/emulated/0/Shuni` instead of the standard app sandbox
/// (`path_provider.getApplicationDocumentsDirectory`), files are preserved even if the app
/// is uninstalled, and they are fully indexable and accessible by general Android file managers.
class StorageService {
  StorageService._(); // Private constructor

  static const String rootPath = '/storage/emulated/0';
  static const String shuniDirPath = '$rootPath/${AppConstants.baseFolder}';
  static const String recordingsDirPath = '$rootPath/${AppConstants.recordingsFolder}';

  /// Ensures that all required directories exist on the filesystem.
  static Future<void> initializeDirectories() async {
    final Directory shuniDir = Directory(shuniDirPath);
    final Directory recDir = Directory(recordingsDirPath);

    if (!await shuniDir.exists()) {
      await shuniDir.create(recursive: true);
    }
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }

    // Create a .nomedia file in the db folder so the database folder is ignored by media scanners
    final Directory dbDir = Directory('$rootPath/${AppConstants.databaseFolder}');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final File nomedia = File('${dbDir.path}/.nomedia');
    if (!await nomedia.exists()) {
      await nomedia.create();
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
    final Directory recDir = Directory(recordingsDirPath);
    
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
    final Directory recDir = Directory(recordingsDirPath);
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
