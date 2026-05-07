import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_entry.dart';
import '../models/employer.dart';
import '../models/tracked_location.dart';
import '../models/imap_config.dart';
import '../models/activity_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;
  DatabaseHelper._init();

  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'zeiterfassung.db');
    return openDatabase(path, version: 9, onCreate: _create, onUpgrade: _upgrade);
  }

  Future<void> _create(Database db, int _) async {
    await db.execute('''
      CREATE TABLE employers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        weekly_hours REAL NOT NULL DEFAULT 40.0,
        fiscal_year_start_month INTEGER NOT NULL DEFAULT 4,
        nas_url TEXT,
        nas_api_key TEXT,
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT
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
        travel_minutes INTEGER NOT NULL DEFAULT 0,
        employer_id TEXT,
        is_special_hours INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _createV2Tables(db);
    await _createV7Tables(db);
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE employers ADD COLUMN fiscal_year_start_month INTEGER NOT NULL DEFAULT 4');
      await db.execute(
          "ALTER TABLE imap_config ADD COLUMN subject_keywords TEXT NOT NULL DEFAULT '[]'");
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE time_entries ADD COLUMN travel_minutes INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE time_entries ADD COLUMN employer_id TEXT');
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE employers ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'");
      await db.execute("ALTER TABLE tracked_locations ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'");
      await db.execute("ALTER TABLE tracked_locations ADD COLUMN employer_id TEXT");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_state (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 7) {
      await _createV7Tables(db);
    }
    if (oldVersion < 8) {
      try {
        await db.execute("ALTER TABLE employers ADD COLUMN deleted_at TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tracked_locations ADD COLUMN deleted_at TEXT");
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
            "ALTER TABLE time_entries ADD COLUMN is_special_hours INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
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
        is_active INTEGER NOT NULL DEFAULT 1,
        employer_id TEXT,
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT
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

  Future<void> _createV7Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_log (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        title TEXT NOT NULL,
        app_name TEXT NOT NULL
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

  Future<List<TimeEntry>> getEntriesForMonth(int year, int month,
      {String? employerId}) async {
    final db = await database;
    final start =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end =
        '${endYear.toString().padLeft(4, '0')}-${endMonth.toString().padLeft(2, '0')}-01';
    final (where, whereArgs) = _employerFilter(
        'date >= ? AND date < ?', [start, end], employerId);
    final rows = await db.query('time_entries',
        where: where, whereArgs: whereArgs, orderBy: 'start_time DESC');
    return rows.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getEntriesForDateRange(DateTime from, DateTime to,
      {String? employerId}) async {
    final db = await database;
    final (where, whereArgs) = _employerFilter(
        'date >= ? AND date <= ?',
        [
          from.toIso8601String().substring(0, 10),
          to.toIso8601String().substring(0, 10)
        ],
        employerId);
    final rows = await db.query('time_entries',
        where: where, whereArgs: whereArgs, orderBy: 'start_time ASC');
    return rows.map(TimeEntry.fromMap).toList();
  }

  Future<List<TimeEntry>> getUnsyncedEntries({String? employerId}) async {
    final db = await database;
    final (where, whereArgs) =
        _employerFilter('is_synced = 0', [], employerId);
    final rows =
        await db.query('time_entries', where: where, whereArgs: whereArgs);
    return rows.map(TimeEntry.fromMap).toList();
  }

  /// Returns (whereClause, whereArgs) with optional employer filter.
  /// NULL employer_id entries are always included (legacy/unassigned entries).
  (String, List<dynamic>) _employerFilter(
      String base, List<dynamic> args, String? employerId) {
    if (employerId == null) return (base, args);
    return (
      '$base AND (employer_id = ? OR employer_id IS NULL)',
      [...args, employerId]
    );
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
    final now = DateTime.now().toIso8601String();
    await db.update('employers', {'deleted_at': now, 'updated_at': now},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Employer>> getEmployers() async {
    final db = await database;
    final rows = await db.query('employers', where: 'deleted_at IS NULL');
    return rows.map(Employer.fromMap).toList();
  }

  /// Alle Employers inkl. soft-deleted – nur für Sync-Push.
  Future<List<Employer>> getAllEmployersForSync() async {
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
    final now = DateTime.now().toIso8601String();
    await db.update('tracked_locations', {'deleted_at': now, 'updated_at': now},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TrackedLocation>> getLocations() async {
    final db = await database;
    final rows = await db.query('tracked_locations',
        where: 'deleted_at IS NULL', orderBy: 'name ASC');
    return rows.map(TrackedLocation.fromMap).toList();
  }

  /// Alle Locations inkl. soft-deleted – nur für Sync-Push.
  Future<List<TrackedLocation>> getAllLocationsForSync() async {
    final db = await database;
    final rows = await db.query('tracked_locations', orderBy: 'name ASC');
    return rows.map(TrackedLocation.fromMap).toList();
  }

  /// Soft-deletes duplicate locations (same name + coordinates ±100 m).
  /// Keeps the entry with the most recent updated_at.
  Future<int> deduplicateLocations() async {
    final db = await database;
    final rows = await db.query('tracked_locations',
        where: 'deleted_at IS NULL', orderBy: 'updated_at DESC');
    final seen = <String>{}; // dedup key → kept
    final now = DateTime.now().toIso8601String();
    int removed = 0;
    for (final row in rows) {
      final name = row['name'] as String;
      final lat  = ((row['latitude']  as num).toDouble() * 1000).round();
      final lon  = ((row['longitude'] as num).toDouble() * 1000).round();
      final key  = '${name}_${lat}_$lon';
      if (seen.contains(key)) {
        await db.update('tracked_locations',
            {'deleted_at': now, 'updated_at': now},
            where: 'id = ?', whereArgs: [row['id']]);
        removed++;
      } else {
        seen.add(key);
      }
    }
    return removed;
  }

  Future<bool> hasLocations() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM tracked_locations');
    return (rows.first['c'] as int? ?? 0) > 0;
  }

  Future<void> upsertLocationsFromServer(List<TrackedLocation> locations) async {
    final db = await database;
    final batch = db.batch();
    for (final loc in locations) {
      if (loc.deletedAt != null) {
        batch.delete('tracked_locations', where: 'id = ?', whereArgs: [loc.id]);
      } else {
        batch.insert('tracked_locations', loc.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<TrackedLocation>> getAllLocations() async {
    final db = await database;
    final rows = await db.query('tracked_locations',
        where: 'deleted_at IS NULL', orderBy: 'name ASC');
    return rows.map(TrackedLocation.fromMap).toList();
  }

  // ── sync_state ────────────────────────────────────────────────────────────

  Future<String?> getSyncState(String key) async {
    final db = await database;
    final rows = await db.query('sync_state', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSyncState(String key, String value) async {
    final db = await database;
    await db.insert('sync_state', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertEmployersFromServer(List<Employer> employers) async {
    final db = await database;
    final batch = db.batch();
    for (final e in employers) {
      if (e.deletedAt != null) {
        batch.delete('employers', where: 'id = ?', whereArgs: [e.id]);
      } else {
        batch.insert('employers', e.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
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

  // ── activity_log ──────────────────────────────────────────────────────────

  Future<void> insertActivityLog(ActivityLog log) async {
    final db = await database;
    await db.insert('activity_log', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ActivityLog>> getActivityLogsForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final rows = await db.query(
      'activity_log',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'start_time ASC',
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<void> deleteActivityLogsForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    await db.delete(
      'activity_log',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [dayStart, dayEnd],
    );
  }

  Future<void> deleteAllActivityLogs() async {
    final db = await database;
    await db.delete('activity_log');
  }
}
