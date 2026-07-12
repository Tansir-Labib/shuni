import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';
import '../models/call_record.dart';
import '../models/app_settings.dart';

/// # DatabaseService
/// 
/// Manages local persistence for call records, user preferences, and app configurations
/// using SQLite.
/// 
/// ## Learning Note
/// Sqflite is the standard SQLite plugin for Flutter.
/// 1. We open a connection by calling `openDatabase`.
/// 2. If it's the first run, the `onCreate` callback runs where we declare tables.
/// 3. If the version changes, `onUpgrade` runs to handle migrations without erasing user data.
/// 4. By wrapping SQLite logic in a central class, we hide SQL queries from UI widgets.
class DatabaseService {
  // Singleton pattern
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  /// Returns the active database instance. If not opened, opens it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database.
  /// We store the database file in `/storage/emulated/0/Shuni/.shuni_db/shuni.db`
  /// so it's fully accessible to the user but hidden from default file views.
  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String dbPath = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Creates tables on database creation.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Table for call recording records
    await db.execute('''
      CREATE TABLE call_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        date_time_ms INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        direction TEXT NOT NULL,
        audio_file_path TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        address TEXT,
        is_bookmarked INTEGER DEFAULT 0,
        notes TEXT,
        is_voip INTEGER DEFAULT 0
      )
    ''');

    // 2. Table for app settings (single row table)
    await db.execute('''
      CREATE TABLE app_settings(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        auto_record INTEGER DEFAULT 1,
        biometric_lock INTEGER DEFAULT 0,
        pin_lock INTEGER DEFAULT 0,
        auto_lock_seconds INTEGER DEFAULT 0,
        auto_backup INTEGER DEFAULT 0,
        backup_wifi_only INTEGER DEFAULT 1,
        audio_quality TEXT DEFAULT 'high',
        show_overlay INTEGER DEFAULT 1,
        cleanup_days INTEGER
      )
    ''');

    // Insert default settings row
    await db.insert('app_settings', {
      'id': 1,
      'auto_record': 1,
      'biometric_lock': 0,
      'pin_lock': 0,
      'auto_lock_seconds': 0,
      'auto_backup': 0,
      'backup_wifi_only': 1,
      'audio_quality': 'high',
      'show_overlay': 1,
      'cleanup_days': null,
    });
  }

  // ==========================================
  // CALL RECORD CRUD OPERATIONS
  // ==========================================

  /// Inserts a new call recording metadata row. Returns the generated auto-increment id.
  Future<int> insertRecord(CallRecord record) async {
    final db = await database;
    return await db.insert(
      'call_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing call record (e.g. toggles bookmark, adds notes).
  Future<int> updateRecord(CallRecord record) async {
    final db = await database;
    return await db.update(
      'call_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Deletes a record from the database by ID.
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'call_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieves a specific call record by ID.
  Future<CallRecord?> getRecord(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return CallRecord.fromMap(maps.first);
  }

  /// Retrieves all records matching optional search queries and filters.
  Future<List<CallRecord>> getAllRecords({
    String? searchQuery,
    String? directionFilter, // 'incoming' or 'outgoing'
    bool? isBookmarkedFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    // Search query matches name or phone number
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += '(contact_name LIKE ? OR phone_number LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    // Direction filter
    if (directionFilter != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'direction = ?';
      whereArgs.add(directionFilter);
    }

    // Bookmarked filter
    if (isBookmarkedFilter != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_bookmarked = ?';
      whereArgs.add(isBookmarkedFilter ? 1 : 0);
    }

    // Date range filter
    if (fromDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date_time_ms >= ?';
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }
    if (toDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date_time_ms <= ?';
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'call_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date_time_ms DESC', // Newest first
    );

    return List.generate(maps.length, (i) => CallRecord.fromMap(maps[i]));
  }

  // ==========================================
  // APP CONFIGURATION / SETTINGS OPERATIONS
  // ==========================================

  /// Retrieves current app configuration parameters.
  Future<AppSettings> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'id = 1',
    );
    
    if (maps.isEmpty) return AppSettings();
    return AppSettings.fromMap(maps.first);
  }

  /// Updates app configurations in database.
  Future<int> updateSettings(AppSettings settings) async {
    final db = await database;
    return await db.update(
      'app_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }

  // ==========================================
  // STATISTICAL QUERIES
  // ==========================================

  /// Gets total count of all recordings.
  Future<int> getRecordCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM call_records');
    return result.first['count'] as int? ?? 0;
  }

  /// Gets total duration of all call recordings combined.
  Future<int> getTotalDuration() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT SUM(duration_seconds) as total FROM call_records');
    return result.first['total'] as int? ?? 0;
  }

  /// Gets total database storage space reported.
  Future<int> getTotalStorageUsed() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT SUM(file_size_bytes) as total FROM call_records');
    return result.first['total'] as int? ?? 0;
  }

  /// Cleans up database items older than the threshold setting.
  Future<int> runAutoCleanup(int days) async {
    final db = await database;
    final int cutoffMs = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    
    // Get list of records to delete so caller can delete physical files
    final List<Map<String, dynamic>> recordsToDelete = await db.query(
      'call_records',
      columns: ['audio_file_path'],
      where: 'date_time_ms < ? AND is_bookmarked = 0',
      whereArgs: [cutoffMs],
    );
    
    // Delete files physically
    for (final row in recordsToDelete) {
      final String? path = row['audio_file_path'] as String?;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    // Delete database entries
    return await db.delete(
      'call_records',
      where: 'date_time_ms < ? AND is_bookmarked = 0',
      whereArgs: [cutoffMs],
    );
  }
}
