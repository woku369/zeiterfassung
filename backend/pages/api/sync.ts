import type { NextApiRequest, NextApiResponse } from 'next';
import { getDb } from '@/lib/db';
import { checkAuth } from '@/lib/auth';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!checkAuth(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    return handleSync(req, res);
  } catch (e) {
    console.error('Sync error:', e);
    return res.status(500).json({ error: 'Sync fehlgeschlagen', detail: String(e) });
  }
}

function handleSync(req: NextApiRequest, res: NextApiResponse) {
  const db = getDb();
  const body = req.body as {
    last_sync?: string;
    entries?: Record<string, unknown>[];
    employers?: Record<string, unknown>[];
    locations?: Record<string, unknown>[];
    projects?: Record<string, unknown>[];
    splits?: Record<string, unknown>[];
    deleted_ids?: string[];
    settings?: Record<string, unknown>;
  };

  const lastSync = body.last_sync ?? '1970-01-01T00:00:00.000Z';
  const now = new Date().toISOString();

  // ── Apply client deletions ────────────────────────────────────────────────
  const clientDeletedIds: string[] = body.deleted_ids ?? [];
  if (clientDeletedIds.length > 0) {
    const delEntry = db.prepare('DELETE FROM time_entries WHERE id = ?');
    const logDel = db.prepare(
      'INSERT OR IGNORE INTO deletion_log (id, deleted_at) VALUES (?, ?)'
    );
    const applyDeletions = db.transaction((ids: string[]) => {
      for (const id of ids) {
        delEntry.run(id);
        logDel.run(id, now);
      }
    });
    applyDeletions(clientDeletedIds);
  }

  // ── Upsert entries ────────────────────────────────────────────────────────
  const entries: Record<string, unknown>[] = body.entries ?? [];
  if (entries.length > 0) {
    const upsertEntry = db.prepare(`
      INSERT INTO time_entries
        (id,date,start_time,end_time,break_minutes,work_type,day_type,note,
         distance_km,start_lat,start_lng,end_lat,end_lng,travel_minutes,
         employer_id,project_id,is_special_hours,is_synced,created_at,updated_at)
      VALUES
        (@id,@date,@start_time,@end_time,@break_minutes,@work_type,@day_type,@note,
         @distance_km,@start_lat,@start_lng,@end_lat,@end_lng,@travel_minutes,
         @employer_id,@project_id,@is_special_hours,1,@created_at,@updated_at)
      ON CONFLICT(id) DO UPDATE SET
        date=excluded.date, start_time=excluded.start_time, end_time=excluded.end_time,
        break_minutes=excluded.break_minutes, work_type=excluded.work_type,
        day_type=excluded.day_type, note=excluded.note, distance_km=excluded.distance_km,
        start_lat=excluded.start_lat, start_lng=excluded.start_lng,
        end_lat=excluded.end_lat, end_lng=excluded.end_lng,
        travel_minutes=excluded.travel_minutes, employer_id=excluded.employer_id,
        project_id=excluded.project_id, is_special_hours=excluded.is_special_hours,
        updated_at=excluded.updated_at
    `);
    const upsertEntries = db.transaction((items: Record<string, unknown>[]) => {
      for (const e of items) {
        upsertEntry.run({
          id: e['id'], date: e['date'], start_time: e['start_time'],
          end_time: e['end_time'] ?? null, break_minutes: e['break_minutes'] ?? 0,
          work_type: e['work_type'] ?? 'homeoffice', day_type: e['day_type'] ?? 'workday',
          note: e['note'] ?? '', distance_km: e['distance_km'] ?? null,
          start_lat: e['start_lat'] ?? null, start_lng: e['start_lng'] ?? null,
          end_lat: e['end_lat'] ?? null, end_lng: e['end_lng'] ?? null,
          travel_minutes: e['travel_minutes'] ?? 0,
          employer_id: e['employer_id'] ?? null, project_id: e['project_id'] ?? null,
          is_special_hours: e['is_special_hours'] ? 1 : 0,
          created_at: e['created_at'], updated_at: now,
        });
      }
    });
    upsertEntries(entries);
  }

  // ── Upsert employers ──────────────────────────────────────────────────────
  const employers: Record<string, unknown>[] = body.employers ?? [];
  if (employers.length > 0) {
    const upsertEmployer = db.prepare(`
      INSERT INTO employers (id,name,weekly_hours,is_active,deleted,created_at,updated_at)
      VALUES (@id,@name,@weekly_hours,@is_active,@deleted,@created_at,@updated_at)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name, weekly_hours=excluded.weekly_hours,
        is_active=excluded.is_active, deleted=excluded.deleted,
        updated_at=excluded.updated_at
    `);
    const upsertEmployers = db.transaction((items: Record<string, unknown>[]) => {
      for (const e of items) {
        upsertEmployer.run({
          id: e['id'], name: e['name'], weekly_hours: e['weekly_hours'] ?? 40.0,
          is_active: e['is_active'] ? 1 : 0, deleted: e['deleted'] ? 1 : 0,
          created_at: e['created_at'] ?? now, updated_at: now,
        });
      }
    });
    upsertEmployers(employers);
  }

  // ── Upsert locations ──────────────────────────────────────────────────────
  const locations: Record<string, unknown>[] = body.locations ?? [];
  if (locations.length > 0) {
    const upsertLocation = db.prepare(`
      INSERT INTO tracked_locations
        (id,name,latitude,longitude,radius_meters,employer_id,auto_clock_in,deleted,created_at,updated_at)
      VALUES
        (@id,@name,@latitude,@longitude,@radius_meters,@employer_id,@auto_clock_in,@deleted,@created_at,@updated_at)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name, latitude=excluded.latitude, longitude=excluded.longitude,
        radius_meters=excluded.radius_meters, employer_id=excluded.employer_id,
        auto_clock_in=excluded.auto_clock_in, deleted=excluded.deleted,
        updated_at=excluded.updated_at
    `);
    const upsertLocations = db.transaction((items: Record<string, unknown>[]) => {
      for (const l of items) {
        upsertLocation.run({
          id: l['id'], name: l['name'], latitude: l['latitude'], longitude: l['longitude'],
          radius_meters: l['radius_meters'] ?? l['radius_m'] ?? 200.0,
          employer_id: l['employer_id'] ?? null,
          auto_clock_in: l['auto_clock_in'] ? 1 : 0,
          deleted: l['deleted'] ? 1 : 0,
          created_at: l['created_at'] ?? now, updated_at: now,
        });
      }
    });
    upsertLocations(locations);
  }

  // ── Upsert projects ───────────────────────────────────────────────────────
  const projects: Record<string, unknown>[] = body.projects ?? [];
  if (projects.length > 0) {
    const upsertProject = db.prepare(`
      INSERT INTO projects (id,name,employer_id,color,deleted,created_at,updated_at)
      VALUES (@id,@name,@employer_id,@color,@deleted,@created_at,@updated_at)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name, employer_id=excluded.employer_id, color=excluded.color,
        deleted=excluded.deleted, updated_at=excluded.updated_at
    `);
    const upsertProjects = db.transaction((items: Record<string, unknown>[]) => {
      for (const p of items) {
        upsertProject.run({
          id: p['id'], name: p['name'], employer_id: p['employer_id'] ?? null,
          color: p['color'] ?? null, deleted: p['deleted'] ? 1 : 0,
          created_at: p['created_at'] ?? now, updated_at: now,
        });
      }
    });
    upsertProjects(projects);
  }

  // ── Upsert project splits ─────────────────────────────────────────────────
  const splits: Record<string, unknown>[] = body.splits ?? [];
  if (splits.length > 0) {
    const upsertSplit = db.prepare(`
      INSERT INTO entry_project_splits (id,entry_id,project_id,minutes,created_at,updated_at)
      VALUES (@id,@entry_id,@project_id,@minutes,@created_at,@updated_at)
      ON CONFLICT(id) DO UPDATE SET
        entry_id=excluded.entry_id, project_id=excluded.project_id,
        minutes=excluded.minutes, updated_at=excluded.updated_at
    `);
    const upsertSplits = db.transaction((items: Record<string, unknown>[]) => {
      for (const s of items) {
        upsertSplit.run({
          id: s['id'], entry_id: s['entry_id'], project_id: s['project_id'],
          minutes: s['minutes'] ?? 0,
          created_at: s['created_at'] ?? now, updated_at: now,
        });
      }
    });
    upsertSplits(splits);
  }

  // ── Settings (LWW: last-write wins, NAS is authoritative store) ───────────
  if (body.settings && Object.keys(body.settings).length > 0) {
    const upsertSetting = db.prepare(
      'INSERT OR REPLACE INTO sync_state (key, value) VALUES (?, ?)'
    );
    const upsertSettings = db.transaction((settings: Record<string, unknown>) => {
      for (const [k, v] of Object.entries(settings)) {
        upsertSetting.run(`setting:${k}`, JSON.stringify(v));
      }
    });
    upsertSettings(body.settings);
  }

  // ── Pull: entries changed since last_sync ─────────────────────────────────
  const deletedSet = new Set(clientDeletedIds);
  const pulledEntries = (db.prepare(
    `SELECT * FROM time_entries WHERE updated_at > ? ORDER BY updated_at`
  ).all(lastSync) as Record<string, unknown>[]).filter(e => !deletedSet.has(e['id'] as string));

  const pulledEmployers = db.prepare(
    `SELECT * FROM employers WHERE updated_at > ? ORDER BY updated_at`
  ).all(lastSync) as Record<string, unknown>[];

  const pulledLocations = db.prepare(
    `SELECT * FROM tracked_locations WHERE updated_at > ? ORDER BY updated_at`
  ).all(lastSync) as Record<string, unknown>[];

  const pulledProjects = db.prepare(
    `SELECT * FROM projects WHERE updated_at > ? ORDER BY updated_at`
  ).all(lastSync) as Record<string, unknown>[];

  // Splits for entries that changed since last_sync
  const pulledSplits = db.prepare(
    `SELECT * FROM entry_project_splits WHERE updated_at > ? ORDER BY updated_at`
  ).all(lastSync) as Record<string, unknown>[];

  // Deletions accumulated on NAS since last_sync (from other devices)
  const serverDeletedIds = (db.prepare(
    `SELECT id FROM deletion_log WHERE deleted_at > ?`
  ).all(lastSync) as { id: string }[])
    .map(r => r.id)
    .filter(id => !clientDeletedIds.includes(id));

  // Saved settings to propagate
  const settingRows = db.prepare(
    `SELECT key, value FROM sync_state WHERE key LIKE 'setting:%'`
  ).all() as { key: string; value: string }[];
  const savedSettings: Record<string, unknown> = {};
  for (const row of settingRows) {
    try { savedSettings[row.key.replace('setting:', '')] = JSON.parse(row.value); }
    catch { savedSettings[row.key.replace('setting:', '')] = row.value; }
  }

  return res.status(200).json({
    server_ts: now,
    entries: pulledEntries,
    employers: pulledEmployers,
    locations: pulledLocations,
    projects: pulledProjects,
    splits: pulledSplits,
    deleted_ids: serverDeletedIds,
    settings: Object.keys(savedSettings).length > 0 ? savedSettings : undefined,
  });
}
