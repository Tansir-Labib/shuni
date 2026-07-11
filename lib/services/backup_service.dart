import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../core/constants.dart';
import 'database_service.dart';

/// # AuthClient
/// 
/// A custom HTTP client that injects OAuth2 headers into every request.
/// Required by the `googleapis` library to authenticate with Google API servers.
class AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// # BackupService
/// 
/// Manages synchronization of recordings and the local SQLite database to the user's
/// personal Google Drive.
/// 
/// ## Google Drive API Design
/// 1. Uses the `drive.file` scope. This is a secure permission scope that ONLY allows our app
///    to view, modify, and delete files/folders created by our app. It cannot see the user's
///    personal photographs, documents, or other folders.
/// 2. Connects using the user's personal Google account, which is completely free.
/// 3. Backs up the SQLite database file (`shuni.db`) along with any `.ogg` voice records.
/// 
/// ## Learning Note
/// Standard commercial systems use centralized backend servers, which cost money.
/// Because Shuni is personal and local, we directly connect from the client (mobile device)
/// to Google's free APIs. This bypasses backend server requirements entirely.
class BackupService {
  // Singleton pattern
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // Request access to files created/opened by the app only
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  /// Starts the Google Sign-in flow. Opens a native overlay popup.
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      // Initialize authenticated client
      final Map<String, String> authHeaders = await _currentUser!.authHeaders;
      final AuthClient authClient = AuthClient(authHeaders);
      _driveApi = drive.DriveApi(authClient);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Logs out and clears connection credentials.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
    } catch (_) {
      // Fail silently
    }
  }

  /// Checks if the user is signed in.
  Future<bool> isSignedIn() async {
    final bool signed = await _googleSignIn.isSignedIn();
    if (signed && _currentUser == null) {
      // Restore previous silent login
      try {
        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser != null) {
          final Map<String, String> authHeaders = await _currentUser!.authHeaders;
          final AuthClient authClient = AuthClient(authHeaders);
          _driveApi = drive.DriveApi(authClient);
        }
      } catch (_) {
        return false;
      }
    }
    return _currentUser != null && _driveApi != null;
  }

  /// Searches for or creates our dedicated backup folder in Google Drive.
  Future<String?> _getOrCreateBackupFolder() async {
    if (_driveApi == null) return null;

    final String query = "mimeType = 'application/vnd.google-apps.folder' and name = '${AppConstants.driveBackupFolder}' and trashed = false";
    
    try {
      final drive.FileList list = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id;
      }

      // Folder doesn't exist, create it
      final drive.File folderMetadata = drive.File()
        ..name = AppConstants.driveBackupFolder
        ..mimeType = 'application/vnd.google-apps.folder';

      final drive.File folder = await _driveApi!.files.create(folderMetadata);
      return folder.id;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a single file to our backup folder.
  Future<bool> uploadFile(File file, String folderId) async {
    if (_driveApi == null) return false;

    try {
      final String filename = basename(file.path);
      
      // Check if file already exists in backup folder to avoid duplicates
      final String query = "'$folderId' in parents and name = '$filename' and trashed = false";
      final drive.FileList list = await _driveApi!.files.list(q: query);

      final drive.File fileMetadata = drive.File()
        ..name = filename
        ..parents = [folderId];

      final drive.Media media = drive.Media(
        file.openRead(),
        await file.length(),
      );

      if (list.files != null && list.files!.isNotEmpty) {
        // Update existing file
        final String existingId = list.files!.first.id!;
        await _driveApi!.files.update(
          fileMetadata,
          existingId,
          uploadMedia: media,
        );
      } else {
        // Upload as new file
        await _driveApi!.files.create(
          fileMetadata,
          uploadMedia: media,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Master function: performs full backup of all audio recordings and the SQLite database.
  Future<bool> runFullBackup() async {
    final bool logged = await isSignedIn();
    if (!logged) return false;

    final String? folderId = await _getOrCreateBackupFolder();
    if (folderId == null) return false;

    try {
      // 1. Back up database
      final String dbPath = '/storage/emulated/0/${AppConstants.databaseFolder}/${AppConstants.databaseName}';
      final File dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await uploadFile(dbFile, folderId);
      }

      // 2. Back up recordings folder files
      final Directory recDir = Directory('/storage/emulated/0/${AppConstants.recordingsFolder}');
      if (await recDir.exists()) {
        final List<FileSystemEntity> entities = await recDir.list().toList();
        for (final FileSystemEntity entity in entities) {
          if (entity is File && entity.path.endsWith('.ogg')) {
            await uploadFile(entity, folderId);
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restores backups from Google Drive by downloading all files back to their local paths.
  Future<bool> runRestore() async {
    final bool logged = await isSignedIn();
    if (!logged) return false;

    if (_driveApi == null) return false;

    try {
      // Find backup folder
      final String queryFolder = "mimeType = 'application/vnd.google-apps.folder' and name = '${AppConstants.driveBackupFolder}' and trashed = false";
      final drive.FileList folderList = await _driveApi!.files.list(q: queryFolder);
      if (folderList.files == null || folderList.files!.isEmpty) return false;

      final String folderId = folderList.files!.first.id!;

      // List all files inside backup folder
      final String queryFiles = "'$folderId' in parents and trashed = false";
      final drive.FileList fileList = await _driveApi!.files.list(q: queryFiles);
      if (fileList.files == null) return false;

      for (final drive.File driveFile in fileList.files!) {
        final String name = driveFile.name!;
        final String id = driveFile.id!;
        
        // Define local path depending on file extension
        String localPath;
        if (name.endsWith('.db')) {
          localPath = '/storage/emulated/0/${AppConstants.databaseFolder}/$name';
        } else {
          localPath = '/storage/emulated/0/${AppConstants.recordingsFolder}/$name';
        }

        // Ensure directories exist
        final File localFile = File(localPath);
        if (!await localFile.parent.exists()) {
          await localFile.parent.create(recursive: true);
        }

        // Download and write
        final drive.Media response = await _driveApi!.files.get(
          id,
          downloadOptions: drive.DownloadOptions.metadata,
        ) as drive.Media;

        final List<int> dataBytes = [];
        await for (final List<int> chunk in response.stream) {
          dataBytes.addAll(chunk);
        }

        await localFile.writeAsBytes(dataBytes, flush: true);
      }

      // Re-trigger database schema migrations/init if needed
      await DatabaseService.instance.database;

      return true;
    } catch (_) {
      return false;
    }
  }
}
