/**
 * Zeiterfassung Backend – standalone Node.js server
 * Kein Docker, kein Build-Schritt. Start: node server.js
 *
 * Umgebungsvariablen (optional):
 *   PORT      HTTP-Port (default 3000)
 *   API_KEY   Authentifizierungs-Key (default: kein Auth)
 *   DATA_DIR  Verzeichnis für SQLite-DB (default: ./data)
 */

const http = require('http');
const fs   = require('fs');
const path = require('path');

// ── Konfiguration ─────────────────────────────────────────────────────────────

const PORT    = process.env.PORT    || 3000;
const API_KEY = process.env.API_KEY || null;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

// ── Datenbank ─────────────────────────────────────────────────────────────────

const Database = require('better-sqlite3');
const db = new Database(path.join(DATA_DIR, 'zeiterfassung.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS employers (
    id                    TEXT PRIMARY KEY,
    name                  TEXT NOT NULL,
    weekly_hours          REAL NOT NULL DEFAULT 40.0,
    fiscal_year_start_month INTEGER NOT NULL DEFAULT 4,
    vacation_days_per_year INTEGER NOT NULL DEFAULT 25,
    monthly_gross         REAL,
    nas_url               TEXT,
    nas_api_key           TEXT,
    updated_at            TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at            TEXT
  );

  CREATE TABLE IF NOT EXISTS time_entries (
    id             TEXT PRIMARY KEY,
    date           TEXT NOT NULL,
    start_time     TEXT NOT NULL,
    end_time       TEXT,
    break_minutes  INTEGER NOT NULL DEFAULT 0,
    work_type      TEXT NOT NULL DEFAULT 'homeoffice',
    day_type       TEXT NOT NULL DEFAULT 'workday',
    note           TEXT DEFAULT '',
    distance_km    REAL,
    start_lat      REAL,
    start_lng      REAL,
    end_lat        REAL,
    end_lng        REAL,
    travel_minutes INTEGER NOT NULL DEFAULT 0,
    employer_id    TEXT,
    is_special_hours INTEGER NOT NULL DEFAULT 0,
    is_synced      INTEGER NOT NULL DEFAULT 1,
    created_at     TEXT NOT NULL,
    updated_at     TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at     TEXT
  );

  CREATE TABLE IF NOT EXISTS tracked_locations (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    latitude    REAL NOT NULL,
    longitude   REAL NOT NULL,
    radius_m    INTEGER NOT NULL DEFAULT 100,
    work_type   TEXT NOT NULL DEFAULT 'office',
    is_active   INTEGER NOT NULL DEFAULT 1,
    employer_id TEXT,
    updated_at  TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at  TEXT
  );

  CREATE TABLE IF NOT EXISTS imap_config (
    id               TEXT PRIMARY KEY,
    employer_id      TEXT,
    host             TEXT NOT NULL,
    port             INTEGER NOT NULL DEFAULT 993,
    use_ssl          INTEGER NOT NULL DEFAULT 1,
    username         TEXT NOT NULL,
    password         TEXT NOT NULL,
    target_folder    TEXT NOT NULL DEFAULT 'Zeiterfassung',
    sender_filter    TEXT DEFAULT '',
    subject_keywords TEXT DEFAULT '',
    updated_at       TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at       TEXT
  );

  CREATE TABLE IF NOT EXISTS projects (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    employer_id TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT
  );

  CREATE TABLE IF NOT EXISTS app_settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_entries_date       ON time_entries(date);
`);

// Idempotente Migrationen für bestehende Installationen
try {
  db.exec("ALTER TABLE time_entries ADD COLUMN is_special_hours INTEGER NOT NULL DEFAULT 0");
} catch (_) { /* Spalte existiert bereits */ }
try {
  db.exec("ALTER TABLE time_entries ADD COLUMN project_id TEXT");
} catch (_) { /* Spalte existiert bereits */ }
try {
  db.exec("ALTER TABLE employers ADD COLUMN vacation_days_per_year INTEGER NOT NULL DEFAULT 25");
} catch (_) { /* Spalte existiert bereits */ }
try {
  db.exec("ALTER TABLE employers ADD COLUMN monthly_gross REAL");
} catch (_) { /* Spalte existiert bereits */ }

db.exec(`
  CREATE INDEX IF NOT EXISTS idx_entries_employer   ON time_entries(employer_id);
  CREATE INDEX IF NOT EXISTS idx_entries_updated    ON time_entries(updated_at);
  CREATE INDEX IF NOT EXISTS idx_employers_updated  ON employers(updated_at);
`);

console.log('DB ready:', path.join(DATA_DIR, 'zeiterfassung.db'));

// ── Auth ──────────────────────────────────────────────────────────────────────

function checkAuth(req) {
  if (!API_KEY) return true;
  return req.headers['x-api-key'] === API_KEY;
}

// ── HTTP-Hilfsfunktionen ──────────────────────────────────────────────────────

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try { resolve(body ? JSON.parse(body) : {}); }
      catch(e) { reject(e); }
    });
    req.on('error', reject);
  });
}

function send(res, status, data) {
  const body = JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

// ── Prepared Statements ───────────────────────────────────────────────────────

const stmts = {
  // time_entries
  upsertEntry: db.prepare(`
    INSERT INTO time_entries
      (id,date,start_time,end_time,break_minutes,work_type,day_type,note,
       distance_km,start_lat,start_lng,end_lat,end_lng,travel_minutes,
       employer_id,project_id,is_special_hours,is_synced,created_at,updated_at,deleted_at)
    VALUES
      (@id,@date,@start_time,@end_time,@break_minutes,@work_type,@day_type,@note,
       @distance_km,@start_lat,@start_lng,@end_lat,@end_lng,@travel_minutes,
       @employer_id,@project_id,@is_special_hours,1,@created_at,@updated_at,@deleted_at)
    ON CONFLICT(id) DO UPDATE SET
      date=excluded.date, start_time=excluded.start_time, end_time=excluded.end_time,
      break_minutes=excluded.break_minutes, work_type=excluded.work_type,
      day_type=excluded.day_type, note=excluded.note, distance_km=excluded.distance_km,
      travel_minutes=excluded.travel_minutes, employer_id=excluded.employer_id,
      project_id=excluded.project_id, is_special_hours=excluded.is_special_hours,
      updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
    WHERE excluded.updated_at > time_entries.updated_at
  `),

  getEntriesSince: db.prepare(
    `SELECT * FROM time_entries WHERE updated_at > ? ORDER BY updated_at`
  ),

  // employers
  upsertEmployer: db.prepare(`
    INSERT INTO employers
      (id,name,weekly_hours,fiscal_year_start_month,vacation_days_per_year,monthly_gross,nas_url,nas_api_key,updated_at,deleted_at)
    VALUES
      (@id,@name,@weekly_hours,@fiscal_year_start_month,@vacation_days_per_year,@monthly_gross,@nas_url,@nas_api_key,@updated_at,@deleted_at)
    ON CONFLICT(id) DO UPDATE SET
      name=excluded.name, weekly_hours=excluded.weekly_hours,
      fiscal_year_start_month=excluded.fiscal_year_start_month,
      vacation_days_per_year=excluded.vacation_days_per_year,
      monthly_gross=excluded.monthly_gross,
      nas_url=excluded.nas_url, nas_api_key=excluded.nas_api_key,
      updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
    WHERE excluded.updated_at > employers.updated_at
  `),

  getEmployersSince: db.prepare(
    `SELECT * FROM employers WHERE updated_at > ? ORDER BY updated_at`
  ),

  // locations
  upsertLocation: db.prepare(`
    INSERT INTO tracked_locations
      (id,name,latitude,longitude,radius_m,work_type,is_active,employer_id,updated_at,deleted_at)
    VALUES
      (@id,@name,@latitude,@longitude,@radius_m,@work_type,@is_active,@employer_id,@updated_at,@deleted_at)
    ON CONFLICT(id) DO UPDATE SET
      name=excluded.name, latitude=excluded.latitude, longitude=excluded.longitude,
      radius_m=excluded.radius_m, work_type=excluded.work_type, is_active=excluded.is_active,
      employer_id=excluded.employer_id, updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
    WHERE excluded.updated_at > tracked_locations.updated_at
  `),

  getLocationsSince: db.prepare(
    `SELECT * FROM tracked_locations WHERE updated_at > ? ORDER BY updated_at`
  ),

  // imap
  upsertImap: db.prepare(`
    INSERT INTO imap_config
      (id,employer_id,host,port,use_ssl,username,password,target_folder,sender_filter,subject_keywords,updated_at,deleted_at)
    VALUES
      (@id,@employer_id,@host,@port,@use_ssl,@username,@password,@target_folder,@sender_filter,@subject_keywords,@updated_at,@deleted_at)
    ON CONFLICT(id) DO UPDATE SET
      employer_id=excluded.employer_id, host=excluded.host, port=excluded.port,
      use_ssl=excluded.use_ssl, username=excluded.username, password=excluded.password,
      target_folder=excluded.target_folder, sender_filter=excluded.sender_filter,
      subject_keywords=excluded.subject_keywords,
      updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
    WHERE excluded.updated_at > imap_config.updated_at
  `),

  getImapSince: db.prepare(
    `SELECT * FROM imap_config WHERE updated_at > ? ORDER BY updated_at`
  ),

  // projects
  upsertProject: db.prepare(`
    INSERT INTO projects (id,name,employer_id,sort_order,updated_at,deleted_at)
    VALUES (@id,@name,@employer_id,@sort_order,@updated_at,@deleted_at)
    ON CONFLICT(id) DO UPDATE SET
      name=excluded.name, employer_id=excluded.employer_id,
      sort_order=excluded.sort_order,
      updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
    WHERE excluded.updated_at > projects.updated_at
  `),

  getProjectsSince: db.prepare(
    `SELECT * FROM projects WHERE updated_at > ? ORDER BY updated_at`
  ),

  // app_settings – LWW per key
  upsertSetting: db.prepare(`
    INSERT INTO app_settings (key, value, updated_at)
    VALUES (@key, @value, @updated_at)
    ON CONFLICT(key) DO UPDATE SET
      value      = excluded.value,
      updated_at = excluded.updated_at
    WHERE excluded.updated_at > app_settings.updated_at
  `),

  getAllSettings: db.prepare(`SELECT key, value, updated_at FROM app_settings`),
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Soft-deletes duplicate locations on the server (same name + coords ±100 m).
 *  Keeps the entry with the most recent updated_at. Idempotent. */
function deduplicateLocations(ts) {
  const rows = db.prepare(
    `SELECT id, name, latitude, longitude FROM tracked_locations
     WHERE deleted_at IS NULL ORDER BY updated_at DESC`
  ).all();
  const seen = new Set();
  const stmt = db.prepare(
    `UPDATE tracked_locations SET deleted_at = ?, updated_at = ? WHERE id = ?`
  );
  for (const row of rows) {
    const key = `${row.name}_${Math.round(row.latitude * 1000)}_${Math.round(row.longitude * 1000)}`;
    if (seen.has(key)) {
      stmt.run(ts, ts, row.id);
    } else {
      seen.add(key);
    }
  }
}

/** Soft-deletes duplicate employers on the server (same name, case-insensitive).
 *  Keeps the entry with the most recent updated_at. Idempotent. */
function deduplicateEmployers(ts) {
  const rows = db.prepare(
    `SELECT id, name FROM employers
     WHERE deleted_at IS NULL ORDER BY updated_at DESC`
  ).all();
  const seen = new Set();
  const stmt = db.prepare(
    `UPDATE employers SET deleted_at = ?, updated_at = ? WHERE id = ?`
  );
  for (const row of rows) {
    const key = row.name.trim().toLowerCase();
    if (seen.has(key)) {
      stmt.run(ts, ts, row.id);
    } else {
      seen.add(key);
    }
  }
}

// ── Routen ────────────────────────────────────────────────────────────────────

const now = () => new Date().toISOString();

async function handleRequest(req, res) {
  const url  = new URL(req.url, `http://localhost`);
  const path_ = url.pathname;
  const method = req.method;

  // CORS für lokale Entwicklung
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-api-key');
  if (method === 'OPTIONS') return send(res, 204, {});

  // Auth
  if (!checkAuth(req)) return send(res, 401, { error: 'Unauthorized' });

  // ── GET /api/health ────────────────────────────────────────────────────────
  if (path_ === '/api/health' && method === 'GET') {
    const counts = {
      employers:   db.prepare('SELECT COUNT(*) as n FROM employers').get().n,
      entries:     db.prepare('SELECT COUNT(*) as n FROM time_entries').get().n,
      locations:   db.prepare('SELECT COUNT(*) as n FROM tracked_locations').get().n,
    };
    return send(res, 200, { ok: true, ...counts, ts: now() });
  }

  // ── POST /api/sync ─────────────────────────────────────────────────────────
  // Bidirektionaler Full-Sync: Client schickt lokale Änderungen,
  // bekommt alle Server-Änderungen seit last_sync zurück.
  if (path_ === '/api/sync' && method === 'POST') {
    const body = await readBody(req);
    const since = body.last_sync || '1970-01-01T00:00:00.000Z';
    const ts = now();

    const pushEntries   = db.transaction(items => items.forEach(e => stmts.upsertEntry.run({
      id: e.id, date: e.date, start_time: e.start_time, end_time: e.end_time ?? null,
      break_minutes: e.break_minutes ?? 0, work_type: e.work_type ?? 'other',
      day_type: e.day_type ?? 'workday', note: e.note ?? '',
      distance_km: e.distance_km ?? null, start_lat: e.start_lat ?? null,
      start_lng: e.start_lng ?? null, end_lat: e.end_lat ?? null, end_lng: e.end_lng ?? null,
      travel_minutes: e.travel_minutes ?? 0, employer_id: e.employer_id ?? null,
      project_id: e.project_id ?? null, is_special_hours: e.is_special_hours ? 1 : 0,
      created_at: e.created_at, updated_at: ts, deleted_at: e.deleted_at ?? null,
    })));

    const pushEmployers = db.transaction(items => items.forEach(e => stmts.upsertEmployer.run({
      id: e.id, name: e.name, weekly_hours: e.weekly_hours ?? 40,
      fiscal_year_start_month: e.fiscal_year_start_month ?? 4,
      vacation_days_per_year: e.vacation_days_per_year ?? 25,
      monthly_gross: e.monthly_gross ?? null,
      nas_url: e.nas_url ?? null, nas_api_key: e.nas_api_key ?? null,
      updated_at: e.updated_at ?? ts, deleted_at: e.deleted_at ?? null,
    })));

    const pushLocations = db.transaction(items => items.forEach(e => stmts.upsertLocation.run({
      id: e.id, name: e.name, latitude: e.latitude, longitude: e.longitude,
      radius_m: e.radius_m ?? 100, work_type: e.work_type ?? 'office',
      is_active: e.is_active ?? 1, employer_id: e.employer_id ?? null,
      updated_at: e.updated_at ?? ts, deleted_at: e.deleted_at ?? null,
    })));

    const pushImap = db.transaction(items => items.forEach(e => stmts.upsertImap.run({
      id: e.id, employer_id: e.employer_id ?? null, host: e.host, port: e.port ?? 993,
      use_ssl: e.use_ssl ?? 1, username: e.username, password: e.password,
      target_folder: e.target_folder ?? 'Zeiterfassung',
      sender_filter: e.sender_filter ?? '', subject_keywords: e.subject_keywords ?? '',
      updated_at: ts, deleted_at: e.deleted_at ?? null,
    })));

    const pushProjects = db.transaction(items => items.forEach(e => stmts.upsertProject.run({
      id: e.id, name: e.name, employer_id: e.employer_id ?? null,
      sort_order: e.sort_order ?? 0,
      updated_at: e.updated_at ?? ts, deleted_at: e.deleted_at ?? null,
    })));

    if (body.entries?.length)   pushEntries(body.entries);
    if (body.employers?.length) pushEmployers(body.employers);
    if (body.locations?.length) pushLocations(body.locations);
    if (body.imap?.length)      pushImap(body.imap);
    if (body.projects?.length)  pushProjects(body.projects);

    // Serverseitige Deduplizierung nach jedem Sync-Push.
    deduplicateLocations(ts);
    deduplicateEmployers(ts);

    // Settings-Sync: LWW per key, client sendet {key: {value, updated_at}}
    if (body.settings && typeof body.settings === 'object') {
      const pushSettings = db.transaction(entries => {
        for (const [key, entry] of Object.entries(entries)) {
          const value = (entry && typeof entry === 'object' && 'value' in entry)
            ? JSON.stringify(entry.value)
            : JSON.stringify(entry);
          const updatedAt = (entry && typeof entry === 'object' && 'updated_at' in entry)
            ? entry.updated_at
            : ts;
          stmts.upsertSetting.run({ key, value, updated_at: updatedAt });
        }
      });
      pushSettings(body.settings);
    }

    // Alle Settings zurückschicken inkl. updated_at für client-seitiges LWW per Key.
    const rawSettings = stmts.getAllSettings.all();
    const settings = {};
    for (const row of rawSettings) {
      try { settings[row.key] = JSON.parse(row.value); } catch { settings[row.key] = row.value; }
      // Companion timestamp key so the client can apply its own per-key LWW.
      if (row.updated_at) settings[`${row.key}_updated_at`] = row.updated_at;
    }

    return send(res, 200, {
      ok: true,
      server_ts: ts,
      entries:   stmts.getEntriesSince.all(since),
      employers: stmts.getEmployersSince.all(since),
      locations: stmts.getLocationsSince.all(since),
      imap:      stmts.getImapSince.all(since),
      projects:  stmts.getProjectsSince.all(since),
      settings,
    });
  }

  // ── POST /api/backup ──────────────────────────────────────────────────────
  if (path_ === '/api/backup' && method === 'POST') {
    const body = await readBody(req);
    const backupPath = path.join(DATA_DIR, 'backup_latest.json');
    fs.writeFileSync(backupPath, JSON.stringify(body, null, 2), 'utf8');
    console.log('Backup gespeichert:', backupPath);
    return send(res, 200, { ok: true, saved_at: now() });
  }

  // ── GET /api/backup ───────────────────────────────────────────────────────
  if (path_ === '/api/backup' && method === 'GET') {
    const backupPath = path.join(DATA_DIR, 'backup_latest.json');
    if (!fs.existsSync(backupPath)) {
      return send(res, 404, { error: 'Kein Backup vorhanden' });
    }
    const content = fs.readFileSync(backupPath, 'utf8');
    const data = JSON.parse(content);
    return send(res, 200, data);
  }

  // ── POST /api/backup/scheduled ────────────────────────────────────────────
  // Empfängt {type: 'daily'|'monthly'|'yearly', data: {...}}
  // Speichert in data/backups/, rotiert daily-Backups auf 30.
  if (path_ === '/api/backup/scheduled' && method === 'POST') {
    const body = await readBody(req);
    const type = body.type;
    if (!['daily', 'monthly', 'yearly'].includes(type)) {
      return send(res, 400, { error: 'Ungültiger Backup-Typ' });
    }
    const backupsDir = path.join(DATA_DIR, 'backups');
    if (!fs.existsSync(backupsDir)) fs.mkdirSync(backupsDir, { recursive: true });

    const today = new Date();
    const pad = n => String(n).padStart(2, '0');
    let filename;
    if (type === 'daily') {
      filename = `daily_${today.getFullYear()}-${pad(today.getMonth()+1)}-${pad(today.getDate())}.json`;
    } else if (type === 'monthly') {
      filename = `monthly_${today.getFullYear()}-${pad(today.getMonth()+1)}.json`;
    } else {
      // yearly – Dateiname aus den Daten ableiten wenn möglich, sonst aktueller Monat
      const ym = `${today.getFullYear()}-${pad(today.getMonth()+1)}`;
      filename = `yearly_${ym}.json`;
    }

    const filePath = path.join(backupsDir, filename);
    fs.writeFileSync(filePath, JSON.stringify(body.data ?? body, null, 2), 'utf8');
    console.log(`Scheduled backup gespeichert: ${filename}`);

    // Rotation für daily: maximal 30 behalten
    if (type === 'daily') {
      const files = fs.readdirSync(backupsDir)
        .filter(f => f.startsWith('daily_') && f.endsWith('.json'))
        .sort(); // lexikografisch = chronologisch dank ISO-Datum
      if (files.length > 30) {
        const toDelete = files.slice(0, files.length - 30);
        for (const f of toDelete) {
          try { fs.unlinkSync(path.join(backupsDir, f)); } catch (_) {}
          console.log(`Altes Daily-Backup gelöscht: ${f}`);
        }
      }
    }
    // monthly und yearly: nie löschen

    return send(res, 200, { ok: true, filename });
  }

  // ── GET /api/backup/list ──────────────────────────────────────────────────
  // Gibt Liste aller Backups zurück, sortiert nach Datum absteigend.
  if (path_ === '/api/backup/list' && method === 'GET') {
    const backupsDir = path.join(DATA_DIR, 'backups');
    if (!fs.existsSync(backupsDir)) {
      return send(res, 200, { backups: [] });
    }
    const files = fs.readdirSync(backupsDir).filter(f => f.endsWith('.json'));
    const backups = files.map(filename => {
      const filePath = path.join(backupsDir, filename);
      const stat = fs.statSync(filePath);
      let type = 'unknown';
      if (filename.startsWith('daily_')) type = 'daily';
      else if (filename.startsWith('monthly_')) type = 'monthly';
      else if (filename.startsWith('yearly_')) type = 'yearly';
      // Datum aus Dateiname extrahieren
      const match = filename.match(/\d{4}-\d{2}(?:-\d{2})?/);
      const date = match ? match[0] : filename;
      return { filename, type, date, size_bytes: stat.size };
    });
    // Absteigend nach Dateiname (= Datum)
    backups.sort((a, b) => b.filename.localeCompare(a.filename));
    return send(res, 200, { backups });
  }

  // ── GET /api/backup/get?file=FILENAME ────────────────────────────────────
  // Gibt ein spezifisches Backup zurück. Sicherheitscheck gegen Path-Traversal.
  if (path_ === '/api/backup/get' && method === 'GET') {
    const filename = url.searchParams.get('file');
    if (!filename) return send(res, 400, { error: 'Parameter "file" fehlt' });
    // Sicherheitscheck: nur einfache Dateinamen ohne Pfadtrenner
    if (filename.includes('/') || filename.includes('\\') || filename.includes('..')) {
      return send(res, 400, { error: 'Ungültiger Dateiname' });
    }
    const backupsDir = path.join(DATA_DIR, 'backups');
    const filePath = path.join(backupsDir, filename);
    // Sicherstellen, dass der aufgelöste Pfad wirklich im backups-Verzeichnis liegt
    const resolved = path.resolve(filePath);
    const resolvedDir = path.resolve(backupsDir);
    if (!resolved.startsWith(resolvedDir + path.sep)) {
      return send(res, 403, { error: 'Zugriff verweigert' });
    }
    if (!fs.existsSync(filePath)) {
      return send(res, 404, { error: 'Backup nicht gefunden' });
    }
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);
    return send(res, 200, data);
  }

  // ── Legacy: POST /api/entries/sync (Rückwärtskompatibilität) ───────────────
  if (path_ === '/api/entries/sync' && method === 'POST') {
    const body = await readBody(req);
    const entries = body.entries || [];
    const ts = now();
    const push = db.transaction(items => items.forEach(e => stmts.upsertEntry.run({
      id: e.id, date: e.date, start_time: e.start_time, end_time: e.end_time ?? null,
      break_minutes: e.break_minutes ?? 0, work_type: e.work_type ?? 'other',
      day_type: e.day_type ?? 'workday', note: e.note ?? '',
      distance_km: e.distance_km ?? null, start_lat: e.start_lat ?? null,
      start_lng: e.start_lng ?? null, end_lat: e.end_lat ?? null, end_lng: e.end_lng ?? null,
      travel_minutes: e.travel_minutes ?? 0, employer_id: e.employer_id ?? null,
      project_id: e.project_id ?? null, is_special_hours: e.is_special_hours ? 1 : 0,
      created_at: e.created_at, updated_at: ts, deleted_at: null,
    })));
    push(entries);
    return send(res, 200, { ok: true, count: entries.length });
  }

  // ── GET /api/entries ───────────────────────────────────────────────────────
  if (path_ === '/api/entries' && method === 'GET') {
    const since = url.searchParams.get('since') || '1970-01-01T00:00:00.000Z';
    const rows = stmts.getEntriesSince.all(since);
    return send(res, 200, { entries: rows });
  }

  send(res, 404, { error: 'Not found' });
}

// ── Server starten ────────────────────────────────────────────────────────────

const server = http.createServer(async (req, res) => {
  try {
    await handleRequest(req, res);
  } catch (err) {
    console.error(err);
    send(res, 500, { error: String(err) });
  }
});

server.listen(PORT, () => {
  console.log(`Zeiterfassung Backend läuft auf Port ${PORT}`);
  console.log(`API_KEY: ${API_KEY ? '*** (gesetzt)' : 'nicht gesetzt (kein Auth)'}`);
  console.log(`DATA_DIR: ${DATA_DIR}`);
});

process.on('SIGTERM', () => { db.close(); process.exit(0); });
process.on('SIGINT',  () => { db.close(); process.exit(0); });
