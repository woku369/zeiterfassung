import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_entry.dart';
import '../models/employer.dart';
import '../models/tracked_location.dart';
import '../models/imap_config.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;
  DatabaseHelper._init();

  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'zeiterfassung.db');
    return openDatabase(path, version: 2, onCreate: _create, onUpgrade: _upgrade);
  }

  Future<void> _create(Database db, int _) async {
    await db.execute('''
      CREATE TABLE employers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        weekly_hours REAL NOT NULL DEFAULT 40.0,
        nas_url TEXT,
        nas_api_key TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE time_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        break_minutes INTEGER NOT NULL DEFAULT 0,
        work_type TEXT NOT NULL DEFAULT 'homeoffice',
        day_type TEXT NOT NULL DEFAULT 'workday',
        note TEXT DEFAULT '',
        distance_km REAL,
        start_lat REAL,
        start_lng REAL,
        end_lat REAL,
        end_lng REAL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await _createV2Tables(db);
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracked_locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL DEFAULT 200.0,
        work_type TEXT NOT NULL DEFAULT 'offsite',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imap_config (
        id TEXT PRIMARY KEY,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 993,
        use_ssl INTEGER NOT NULL DEFAULT 1,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        inbox_target_folder TEXT NOT NULL DEFAULT 'Gurktaler',
        sent_target_folder TEXT NOT NULL DEFAULT 'Gurktaler/Gesendet',
        watch_addresses TEXT NOT NULL DEFAULT '[]',
        subject_keywords TEXT NOT NULL DEFAULT '[]',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // ── time_entries ──────────────────────────────────────────────────────────

  Future<void> insertEntry(TimeEntry e) async {
    final db = await database;
    await db.insert('time_entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntry(TimeEntry e) async {
    final db = await database;
    await db.update('time_entries', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('time_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TimeEntry>> getEntriesForMonth(int year, int month) async {
    final db = await database;
    final start = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end = '${endYear.toString().padLeft(4, '0')}-${endMonth.toString().padLeft(2, '0')}-01';
    final rows = await db.query(
      'time_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'start_time DESC',
    );
    return rows.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getEntriesForDateRange(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'time_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String().substring(0, 10), to.toIso8601String().substring(0, 10)],
      orderBy: 'start_time ASC',
    );
    return rows.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getUnsyncedEntries() async {
    final db = await database;
    final rows = await db.query('time_entries', where: 'is_synced = 0');
    return rows.map(TimeEntry.fromMap).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE time_entries SET is_synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<void> insertOrUpdateEntries(List<TimeEntry> entries) async {
    final db = await database;
    final batch = db.batch();
    for (final e in entries) {
      batch.insert('time_entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ── employers ─────────────────────────────────────────────────────────────

  Future<void> insertEmployer(Employer e) async {
    final db = await database;
    await db.insert('employers', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEmployer(Employer e) async {
    final db = await database;
    await db.update('employers', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEmployer(String id) async {
    final db = await database;
    await db.delete('employers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Employer>> getEmployers() async {
    final db = await database;
    final rows = await db.query('employers');
    return rows.map(Employer.fromMap).toList();
  }

  // ── tracked_locations ─────────────────────────────────────────────────────

  Future<void> insertLocation(TrackedLocation loc) async {
    final db = await database;
    await db.insert('tracked_locations', loc.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLocation(TrackedLocation loc) async {
    final db = await database;
    await db.update('tracked_locations', loc.toMap(), where: 'id = ?', whereArgs: [loc.id]);
  }

  Future<void> deleteLocation(String id) async {
    final db = await database;
    await db.delete('tracked_locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TrackedLocation>> getLocations() async {
    final db = await database;
    final rows = await db.query('tracked_locations', orderBy: 'name ASC');
    return rows.map(TrackedLocation.fromMap).toList();
  }

  // ── imap_config ───────────────────────────────────────────────────────────

  Future<void> saveImapConfig(ImapConfig cfg) async {
    final db = await database;
    await db.insert('imap_config', cfg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ImapConfig?> getImapConfig() async {
    final db = await database;
    final rows = await db.query('imap_config', limit: 1);
    if (rows.isEmpty) return null;
    return ImapConfig.fromMap(rows.first);
  }

  Future<void> deleteImapConfig(String id) async {
    final db = await database;
    await db.delete('imap_config', where: 'id = ?', whereArgs: [id]);
  }
}
