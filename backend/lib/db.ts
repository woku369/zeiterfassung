import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const DATA_DIR = process.env.DATA_DIR ?? path.join(process.cwd(), 'data');
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

const DB_PATH = path.join(DATA_DIR, 'zeiterfassung.db');

let _db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (_db) return _db;
  _db = new Database(DB_PATH);
  _db.pragma('journal_mode = WAL');
  _db.pragma('foreign_keys = ON');
  initSchema(_db);
  return _db;
}

function initSchema(db: Database.Database) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS time_entries (
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
      is_synced INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE INDEX IF NOT EXISTS idx_entries_date ON time_entries(date);

    CREATE TABLE IF NOT EXISTS employers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      weekly_hours REAL NOT NULL DEFAULT 40.0,
      is_active INTEGER NOT NULL DEFAULT 0,
      deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS tracked_locations (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      radius_meters REAL NOT NULL DEFAULT 200.0,
      employer_id TEXT,
      auto_clock_in INTEGER NOT NULL DEFAULT 0,
      deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      employer_id TEXT,
      color INTEGER,
      deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS deletion_log (
      id TEXT PRIMARY KEY,
      deleted_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS entry_project_splits (
      id TEXT PRIMARY KEY,
      entry_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      minutes INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE INDEX IF NOT EXISTS idx_splits_entry ON entry_project_splits(entry_id);

    CREATE TABLE IF NOT EXISTS activity_log (
      id TEXT PRIMARY KEY,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      title TEXT NOT NULL,
      app_name TEXT NOT NULL,
      device_id TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE INDEX IF NOT EXISTS idx_activity_log_start ON activity_log(start_time);

    CREATE TABLE IF NOT EXISTS sync_state (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);
}
