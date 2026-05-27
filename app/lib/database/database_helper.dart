import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_entry.dart';
import '../models/employer.dart';
import '../models/tracked_location.dart';
import '../models/imap_config.dart';
import '../models/activity_log.dart';
import '../models/project.dart';
import '../models/trip_record.dart';
import '../models/entry_project_split.dart';
import '../services/holiday_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;
  DatabaseHelper._init();

  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'zeiterfassung.db');
    return openDatabase(
      path,
      version: 19,
      onCreate: _create,
      onUpgrade: _upgrade,
      onOpen: (db) async => db.rawQuery('PRAGMA journal_mode=WAL'),
    );
  }

  Future<void> _create(Database db, int _) async {
    await db.execute('''
      CREATE TABLE employers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        weekly_hours REAL NOT NULL DEFAULT 40.0,
        fiscal_year_start_month INTEGER NOT NULL DEFAULT 4,
        vacation_days_per_year INTEGER NOT NULL DEFAULT 25,
        nas_url TEXT,
        nas_api_key TEXT,
        monthly_gross REAL,
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
        project_id TEXT,
        is_special_hours INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        is_clocking INTEGER NOT NULL DEFAULT 0,
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
    await _createV10Tables(db);
    await _createV11Tables(db);
    await _createV13Tables(db);
    await _createV14Tables(db);
    await _createV15Tables(db);
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
    if (oldVersion < 10) {
      await _createV10Tables(db);
      try {
        await db.execute("ALTER TABLE time_entries ADD COLUMN project_id TEXT");
      } catch (_) {}
    }
    if (oldVersion < 11) {
      await _createV11Tables(db);
    }
    if (oldVersion < 12) {
      try {
        await db.execute(
            'ALTER TABLE employers ADD COLUMN vacation_days_per_year INTEGER NOT NULL DEFAULT 25');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      await _createV13Tables(db);
    }
    if (oldVersion < 14) {
      await _createV14Tables(db);
    }
    if (oldVersion < 15) {
      await _createV15Tables(db);
    }
    if (oldVersion < 16) {
      await _fixDayTypes(db);
    }
    if (oldVersion < 17) {
      await db.execute('ALTER TABLE employers ADD COLUMN monthly_gross REAL');
    }
    if (oldVersion < 18) {
      await db.execute('ALTER TABLE tracked_locations ADD COLUMN default_km REAL');
    }
    if (oldVersion < 19) {
      await db.execute('ALTER TABLE time_entries ADD COLUMN is_clocking INTEGER NOT NULL DEFAULT 0');
    }
  }

  /// Retroactively corrects day_type for all entries based on their date.
  /// Runs once as migration v16; also called from _create for fresh installs
  /// (no-op since there are no entries yet).
  Future<void> _fixDayTypes(Database db) async {
    final rows = await db.query('time_entries', columns: ['id', 'date']);
    if (rows.isEmpty) return;
    final batch = db.batch();
    for (final row in rows) {
      final rawDate = row['date'] as String;
      // Support both 'YYYY-MM-DD' and 'YYYY-MM-DDThh:mm:ss...' formats.
      final date = DateTime.parse(rawDate.length > 10 ? rawDate.substring(0, 10) : rawDate);
      final correct = HolidayService.instance.isHoliday(date)
          ? 'holiday'
          : date.weekday == 6
              ? 'saturday'
              : date.weekday == 7
                  ? 'sunday'
                  : 'workday';
      batch.update('time_entries', {'day_type': correct},
          where: 'id = ?', whereArgs: [row['id']]);
    }
    await batch.commit(noResult: true);
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
        default_km REAL,
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

  Future<void> _createV10Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        employer_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _createV11Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_lat REAL NOT NULL,
        start_lng REAL NOT NULL,
        end_lat REAL,
        end_lng REAL,
        start_address TEXT,
        end_address TEXT,
        distance_km REAL NOT NULL DEFAULT 0,
        linked_entry_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV13Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deletion_log (
        id TEXT PRIMARY KEY,
        deleted_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV15Tables(Database db) async {
    // Add pooling columns to activity_log; wrap in try/catch – safe on fresh install
    // (the _createV7Tables already creates the table without these columns).
    try {
      await db.execute('ALTER TABLE activity_log ADD COLUMN device_id TEXT');
    } catch (_) {}
    try {
      await db.execute(
          'ALTER TABLE activity_log ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
    } catch (_) {}
  }

  Future<void> _createV14Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entry_project_splits (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        minutes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_splits_entry ON entry_project_splits(entry_id)');
  }

  // ── entry_project_splits ──────────────────────────────────────────────────

  Future<List<EntryProjectSplit>> getSplitsForEntry(String entryId) async {
    final db = await database;
    final rows = await db.query('entry_project_splits',
        where: 'entry_id = ?', whereArgs: [entryId], orderBy: 'created_at ASC');
    return rows.map(EntryProjectSplit.fromMap).toList();
  }

  /// Loads splits for multiple entries at once; returns a map entry_id → splits.
  Future<Map<String, List<EntryProjectSplit>>> getSplitsForEntries(
      List<String> entryIds) async {
    if (entryIds.isEmpty) return {};
    final db = await database;
    final placeholders = entryIds.map((_) => '?').join(',');
    final rows = await db.rawQuery(
        'SELECT * FROM entry_project_splits WHERE entry_id IN ($placeholders) ORDER BY created_at ASC',
        entryIds);
    final result = <String, List<EntryProjectSplit>>{};
    for (final row in rows) {
      final split = EntryProjectSplit.fromMap(row);
      result.putIfAbsent(split.entryId, () => []).add(split);
    }
    return result;
  }

  /// Replaces all splits for [entryId] with [splits].
  Future<void> saveSplitsForEntry(
      String entryId, List<EntryProjectSplit> splits) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('entry_project_splits',
        where: 'entry_id = ?', whereArgs: [entryId]);
    for (final s in splits) {
      batch.insert('entry_project_splits', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteSplitsForEntry(String entryId) async {
    final db = await database;
    await db.delete('entry_project_splits',
        where: 'entry_id = ?', whereArgs: [entryId]);
  }

  /// All splits for sync push (no soft-delete, just the full table).
  Future<List<EntryProjectSplit>> getAllSplitsForSync() async {
    final db = await database;
    final rows = await db.query('entry_project_splits');
    return rows.map(EntryProjectSplit.fromMap).toList();
  }

  /// Upsert splits received from server.
  Future<void> upsertSplitsFromServer(
      List<EntryProjectSplit> splits) async {
    if (splits.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final s in splits) {
      batch.insert('entry_project_splits', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ── deletion_log ──────────────────────────────────────────────────────────

  Future<void> logDeletion(String id) async {
    final db = await database;
    await db.insert('deletion_log', {
      'id': id,
      'deleted_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> logDeletions(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      batch.insert('deletion_log', {'id': id, 'deleted_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// Alle lokal protokollierten Löschungen seit [since] (für Sync-Push).
  Future<List<String>> getDeletionsSince(String since) async {
    final db = await database;
    final rows = await db.query('deletion_log',
        columns: ['id'],
        where: 'deleted_at > ?',
        whereArgs: [since]);
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Wendet vom Server empfangene Löschungen lokal an.
  Future<void> applyRemoteDeletions(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      batch.delete('time_entries', where: 'id = ?', whereArgs: [id]);
      batch.insert('deletion_log', {'id': id, 'deleted_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ── trips ─────────────────────────────────────────────────────────────────

  Future<void> insertTrip(TripRecord t) async {
    final db = await database;
    await db.insert('trips', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(TripRecord t) async {
    final db = await database;
    await db.update('trips', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TripRecord>> getTrips({int limit = 200}) async {
    final db = await database;
    final rows = await db.query('trips',
        orderBy: 'start_time DESC', limit: limit);
    return rows.map(TripRecord.fromMap).toList();
  }

  Future<TripRecord?> getOpenTrip() async {
    final db = await database;
    final rows = await db.query('trips',
        where: 'end_time IS NULL', orderBy: 'start_time DESC', limit: 1);
    return rows.isEmpty ? null : TripRecord.fromMap(rows.first);
  }

  // ── time_entries ──────────────────────────────────────────────────────────

  Future<void> insertEntry(TimeEntry e) async {
    final db = await database;
    await db.insert('time_entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntry(TimeEntry e) async {
    final db = await database;
    // Always reset is_synced so the change gets pushed to NAS on next sync.
    final map = e.toMap()..['is_synced'] = 0;
    await db.update('time_entries', map, where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> markAllUnsynced() async {
    final db = await database;
    return db.update('time_entries', {'is_synced': 0});
  }

  /// Applies § 11 AZG auto-pause (30 min) to historical entries:
  /// break_minutes = 0, end_time set, duration ≥ 6h, not homeoffice/absence.
  Future<void> deleteEntry(String id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('entry_project_splits', where: 'entry_id = ?', whereArgs: [id]);
    batch.delete('time_entries', where: 'id = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
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

  /// Returns the one open entry (end_time IS NULL) regardless of employer.
  /// Used by geofencing SKIP check — intentionally cross-employer and cross-day.
  Future<TimeEntry?> getAnyActiveEntry() async {
    final db = await database;
    final rows = await db.query('time_entries',
        where: "end_time IS NULL AND is_clocking = 1 AND work_type NOT IN ('vacation','sick','compensatoryLeave')",
        orderBy: 'start_time DESC',
        limit: 1);
    return rows.isEmpty ? null : TimeEntry.fromMap(rows.first);
  }

  /// Returns open entry from today across all employers (for the active timer UI).
  Future<TimeEntry?> getTodayActiveEntry(String today) async {
    final db = await database;
    final rows = await db.query('time_entries',
        where: "end_time IS NULL AND is_clocking = 1 AND date = ? AND work_type NOT IN ('vacation','sick','compensatoryLeave')",
        whereArgs: [today],
        orderBy: 'start_time DESC',
        limit: 1);
    return rows.isEmpty ? null : TimeEntry.fromMap(rows.first);
  }

  /// Returns the oldest open entry from before today (stale open entry warning).
  Future<TimeEntry?> getStaleOpenEntry(String today) async {
    final db = await database;
    final rows = await db.query('time_entries',
        where: "end_time IS NULL AND date < ? AND work_type NOT IN ('vacation','sick','compensatoryLeave')",
        whereArgs: [today],
        orderBy: 'start_time ASC',
        limit: 1);
    return rows.isEmpty ? null : TimeEntry.fromMap(rows.first);
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

    // Split: entries with end_time can always be replaced (they're immutable).
    // Entries without end_time (still "active" on server) must not overwrite a
    // locally-closed entry — that would resurrect a stale open entry when the
    // clock-out was never pushed to NAS (e.g. network failure on Android).
    final closed  = entries.where((e) => e.endTime != null).toList();
    final open    = entries.where((e) => e.endTime == null).toList();

    final batch = db.batch();
    for (final e in closed) {
      batch.insert('time_entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);

    for (final e in open) {
      final existing = await db.query('time_entries',
          columns: ['end_time'], where: 'id = ?', whereArgs: [e.id], limit: 1);
      if (existing.isNotEmpty && existing.first['end_time'] != null) continue;
      await db.insert('time_entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Findet Einträge, die am selben Tag beim selben Arbeitgeber innerhalb
  /// von 5 Minuten starten — wahrscheinliche Mehrfacheinträge.
  /// Gibt Gruppen zurück; jede Gruppe enthält ≥ 2 Einträge.
  Future<List<List<TimeEntry>>> findDuplicates() async {
    final db = await database;
    final rows = await db.query('time_entries',
        orderBy: 'employer_id, date, start_time ASC');
    final all = rows.map(TimeEntry.fromMap).toList();

    final groups = <List<TimeEntry>>[];
    var i = 0;
    while (i < all.length) {
      final group = [all[i]];
      var j = i + 1;
      while (j < all.length) {
        final a = group.first;
        final b = all[j];
        if (a.date.year != b.date.year ||
            a.date.month != b.date.month ||
            a.date.day != b.date.day ||
            a.employerId != b.employerId) break;
        final diffMin = b.startTime.difference(a.startTime).inMinutes.abs();
        if (diffMin <= 5) {
          group.add(b);
          j++;
        } else {
          break;
        }
      }
      if (group.length >= 2) groups.add(group);
      i = j;
    }
    return groups;
  }

  /// Löscht Duplikate: behält pro Gruppe den "besten" Eintrag
  /// (Ende gesetzt > längste Notiz > ältestes created_at).
  Future<int> deleteDuplicates(List<List<TimeEntry>> groups) async {
    final db = await database;
    var deleted = 0;
    final deletedIds = <String>[];
    for (final group in groups) {
      final keep = group.reduce((a, b) {
        final aHasEnd = a.endTime != null;
        final bHasEnd = b.endTime != null;
        if (aHasEnd && !bHasEnd) return a;
        if (bHasEnd && !aHasEnd) return b;
        if ((a.note?.length ?? 0) != (b.note?.length ?? 0)) {
          return (a.note?.length ?? 0) > (b.note?.length ?? 0) ? a : b;
        }
        return a.createdAt.isBefore(b.createdAt) ? a : b;
      });
      for (final e in group) {
        if (e.id != keep.id) {
          await db.delete('time_entries', where: 'id = ?', whereArgs: [e.id]);
          deletedIds.add(e.id);
          deleted++;
        }
      }
    }
    // Löschungen protokollieren → werden beim nächsten Sync an NAS + andere Geräte übertragen
    await logDeletions(deletedIds);
    return deleted;
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
    for (final loc in locations) {
      // Name-based merge: if a local record with the same name but a different
      // UUID exists (e.g. created by seed on reinstall), remove it first so we
      // don't accumulate duplicates every time NAS data is pulled down.
      await db.delete(
        'tracked_locations',
        where: 'name = ? AND id != ?',
        whereArgs: [loc.name, loc.id],
      );
      await db.insert('tracked_locations', loc.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
    for (final e in employers) {
      // monthly_gross is device-local; the NAS doesn't manage it.
      // Preserve the local value instead of overwriting it with server null.
      final map = e.toMap();
      if (e.monthlyGross == null) {
        final existing = await db.query('employers',
            columns: ['monthly_gross'], where: 'id = ?', whereArgs: [e.id], limit: 1);
        if (existing.isNotEmpty && existing.first['monthly_gross'] != null) {
          map['monthly_gross'] = existing.first['monthly_gross'];
        }
      }
      await db.insert('employers', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
    await db.insert('activity_log', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertActivityLogs(List<ActivityLog> logs) async {
    if (logs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final log in logs) {
      // ignore: Android IDs are deterministic (session_${startMs}_$pkg); replacing
      // would reset is_synced=0 on every loadSessions() call since toMap() omits that field.
      batch.insert('activity_log', log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
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

  Future<List<ActivityLog>> getUnsyncedActivityLogs() async {
    final db = await database;
    final rows = await db.query('activity_log',
        where: 'is_synced = 0 OR is_synced IS NULL');
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<void> markActivityLogsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.rawUpdate(
        'UPDATE activity_log SET is_synced = 1 WHERE id IN ($placeholders)',
        ids);
  }

  Future<void> upsertActivityLogsFromServer(List<ActivityLog> logs) async {
    if (logs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final log in logs) {
      // Mark as synced = 1 so we don't push foreign logs back on next sync
      final map = {...log.toMap(), 'is_synced': 1};
      batch.insert('activity_log', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
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

  // ── projects ──────────────────────────────────────────────────────────────

  Future<void> insertProject(Project p) async {
    final db = await database;
    await db.insert('projects', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProject(Project p) async {
    final db = await database;
    await db.update('projects', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update('projects', {'deleted_at': now, 'updated_at': now},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Project>> getProjects({String? employerId}) async {
    final db = await database;
    if (employerId != null) {
      final rows = await db.query('projects',
          where: 'deleted_at IS NULL AND employer_id = ?',
          whereArgs: [employerId],
          orderBy: 'sort_order ASC, name ASC');
      return rows.map(Project.fromMap).toList();
    }
    final rows = await db.query('projects',
        where: 'deleted_at IS NULL', orderBy: 'sort_order ASC, name ASC');
    return rows.map(Project.fromMap).toList();
  }

  Future<List<Project>> getAllProjectsForSync() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'updated_at ASC');
    return rows.map(Project.fromMap).toList();
  }

  Future<void> upsertProjectsFromServer(List<Project> projects) async {
    final db = await database;
    final batch = db.batch();
    for (final p in projects) {
      batch.insert('projects', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
