#!/usr/bin/env python3
"""
push_to_nas.py – Lokale SQLite-Datenbank → NAS-Backend synchronisieren.

Liest alle Einträge, Arbeitgeber und Standorte aus der lokalen App-Datenbank
und überträgt sie per POST /api/sync an das NAS-Backend.

Aufruf:
    python push_to_nas.py "C:\\Users\\wolfg\\...\\zeiterfassung.db"

    Optional mit anderem NAS-Ziel:
    python push_to_nas.py "<db-pfad>" --url http://100.121.103.107:3000 --key ZE-Gurktaler-2026
"""

import sqlite3
import json
import urllib.request
import urllib.error
import argparse
import sys
import os

# ── Standardkonfiguration ─────────────────────────────────────────────────────

DEFAULT_URL = "http://100.121.103.107:3000"
DEFAULT_KEY = "ZE-Gurktaler-2026"

# ── Argument-Parser ───────────────────────────────────────────────────────────

parser = argparse.ArgumentParser(description="Zeiterfassung: lokale DB → NAS sync")
parser.add_argument("db_path", help="Pfad zur lokalen zeiterfassung.db")
parser.add_argument("--url", default=DEFAULT_URL, help="NAS-Backend-URL")
parser.add_argument("--key", default=DEFAULT_KEY, help="API-Key")
args = parser.parse_args()

if not os.path.exists(args.db_path):
    print(f"FEHLER: Datei nicht gefunden: {args.db_path}")
    sys.exit(1)

# ── Datenbank lesen ───────────────────────────────────────────────────────────

conn = sqlite3.connect(args.db_path)
conn.row_factory = sqlite3.Row

def rows_to_dicts(rows):
    return [dict(r) for r in rows]

# Arbeitgeber
employers = rows_to_dicts(conn.execute("SELECT * FROM employers").fetchall())
print(f"Arbeitgeber:  {len(employers)}")

# Zeiteinträge
entries_raw = rows_to_dicts(conn.execute("SELECT * FROM time_entries").fetchall())
entries = []
for e in entries_raw:
    entries.append({
        "id":            e["id"],
        "date":          e["date"],
        "start_time":    e["start_time"],
        "end_time":      e.get("end_time"),
        "break_minutes": e.get("break_minutes", 0),
        "work_type":     e.get("work_type", "other"),
        "day_type":      e.get("day_type", "workday"),
        "note":          e.get("note", ""),
        "distance_km":   e.get("distance_km"),
        "start_lat":     e.get("start_lat"),
        "start_lng":     e.get("start_lng"),
        "end_lat":       e.get("end_lat"),
        "end_lng":       e.get("end_lng"),
        "travel_minutes":e.get("travel_minutes", 0),
        "employer_id":   e.get("employer_id"),
        "created_at":    e["created_at"],
    })
print(f"Zeiteinträge: {len(entries)}")

# Standorte (radius_meters → radius_m für NAS-Schema)
locations_raw = rows_to_dicts(conn.execute("SELECT * FROM tracked_locations").fetchall())
locations = []
for loc in locations_raw:
    radius = loc.get("radius_m") or loc.get("radius_meters") or 200
    locations.append({
        "id":          loc["id"],
        "name":        loc["name"],
        "latitude":    loc["latitude"],
        "longitude":   loc["longitude"],
        "radius_m":    int(radius),
        "work_type":   loc.get("work_type", "office"),
        "is_active":   loc.get("is_active", 1),
        "employer_id": loc.get("employer_id"),
    })
print(f"Standorte:    {len(locations)}")

conn.close()

# ── An NAS senden ─────────────────────────────────────────────────────────────

payload = json.dumps({
    "last_sync": "1970-01-01T00:00:00.000Z",
    "employers": employers,
    "entries":   entries,
    "locations": locations,
}).encode("utf-8")

url = f"{args.url.rstrip('/')}/api/sync"
print(f"\nSende an: {url}")

req = urllib.request.Request(
    url,
    data=payload,
    headers={
        "Content-Type": "application/json",
        "x-api-key":    args.key,
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read().decode("utf-8"))
    print(f"\nErfolg!")
    print(f"  Server-Zeitstempel: {result.get('server_ts', '?')}")
    print(f"  Einträge am Server: {len(result.get('entries', []))}")
    print(f"  Arbeitgeber:        {len(result.get('employers', []))}")
    print(f"  Standorte:          {len(result.get('locations', []))}")
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", errors="replace")
    print(f"\nFEHLER HTTP {e.code}: {body}")
    sys.exit(1)
except Exception as e:
    print(f"\nFEHLER: {e}")
    sys.exit(1)
