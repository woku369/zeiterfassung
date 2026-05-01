"""
Stempeluhr 2.1 XLSX → zeiterfassung.db Importer
Aufruf: python import_stempeluhr.py

Liest alle .xlsx-Dateien aus XLSX_DIR und schreibt die Einträge
direkt in die SQLite-Datenbank der Zeiterfassung-App.
"""

import sqlite3, os, glob, re, uuid, sys
from pathlib import Path
from datetime import datetime, date, timedelta

try:
    import openpyxl
except ImportError:
    print("openpyxl fehlt. Bitte: pip install openpyxl")
    sys.exit(1)

# ── Konfiguration ────────────────────────────────────────────────────────────

# Ordner mit den XLSX-Dateien
XLSX_DIR = r"C:\Users\wolfg\zeiterfassung\arbeitszeiten gurktaler"

# Mögliche Pfade für die Datenbank (wird der erste existierende verwendet)
DB_CANDIDATES = [
    Path.home() / "Documents" / "zeiterfassung.db",
    Path.home() / "zeiterfassung.db",
    Path(os.getenv("APPDATA", "")) / "zeiterfassung" / "zeiterfassung.db",
    Path(os.getenv("LOCALAPPDATA", "")) / "zeiterfassung" / "zeiterfassung.db",
    # Flutter Windows debug: läuft aus dem build-Ordner
    Path(__file__).parent / "app" / "zeiterfassung.db",
]

# ── Hilfsfunktionen ──────────────────────────────────────────────────────────

AT_HOLIDAYS = {
    (1, 1), (6, 1), (1, 5), (15, 8), (26, 10), (1, 11), (8, 12), (25, 12), (26, 12),
    # Bewegliche Feiertage werden hier nicht berechnet — Tagtyp bleibt workday
}

def day_type(d: date) -> str:
    if (d.day, d.month) in AT_HOLIDAYS:
        return "holiday"
    if d.isoweekday() == 6:
        return "saturday"
    if d.isoweekday() == 7:
        return "sunday"
    return "workday"

def ort_to_work_type(ort: str) -> str:
    o = ort.lower().strip()
    if "home" in o or o == "ho":
        return "homeoffice"
    if o:
        return "offsite"   # Mobil/Außen/Gurk = Außer-Haus, nicht Fahrt
    return "other"

def cell_str(row, col: int) -> str:
    if col >= len(row):
        return ""
    v = row[col].value
    if v is None:
        return ""
    if isinstance(v, datetime):
        return v.strftime("%H:%M")
    if isinstance(v, date):
        return v.strftime("%d.%m.%Y")
    return str(v).strip()

def parse_time(base: date, s: str):
    s = s.strip().replace(",", ":")
    m = re.match(r'^(\d{1,2})[:\.](\d{2})', s)
    if not m:
        return None
    return datetime(base.year, base.month, base.day, int(m[1]), int(m[2]))

def parse_break(s: str) -> int:
    s = s.strip().replace(",", ".")
    if not s or s in ("0", "0.0", "0.00"):
        return 0
    m = re.match(r'^(\d{1,2}):(\d{2})$', s)
    if m:
        return int(m[1]) * 60 + int(m[2])
    try:
        return round(float(s) * 60)
    except ValueError:
        return 0

def stable_id(date_str: str, start: datetime) -> str:
    key = f"{date_str}|{start.hour}:{start.minute:02d}"
    return str(uuid.uuid5(uuid.NAMESPACE_URL, key))

# ── XLSX parsen ──────────────────────────────────────────────────────────────

DAY_PATTERN = re.compile(r'^\d{1,2}\s+[A-Za-zÄÖÜäöü]')
MM_YYYY     = re.compile(r'(\d{2})\.(\d{4})')

def parse_xlsx(path: str, employer_id: str | None):
    wb = openpyxl.load_workbook(path, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows())

    year = month = None
    header_row = -1
    first_data_row = -1
    col_tag = 0

    # Alle Zeilen scannen — ersten "01 Mi"-artigen Eintrag finden
    for ri, row in enumerate(rows):
        for ci, cell in enumerate(row):
            val = str(cell.value or "").strip()
            if DAY_PATTERN.match(val):
                first_data_row = ri
                header_row = ri - 1
                col_tag = ci
                break
        if first_data_row >= 0:
            break

    if first_data_row < 0:
        print(f"  ⚠ Format nicht erkannt: {os.path.basename(path)}")
        print("  Erste 8 Zeilen:")
        for ri, row in enumerate(rows[:8]):
            cells = [f"[{ci}:{repr(str(c.value or '')[:20])}]" for ci, c in enumerate(row) if c.value is not None]
            print(f"    Z{ri+1}: {' '.join(cells)}")
        return []

    # Monat/Jahr suchen
    for ri in range(first_data_row):
        text = " ".join(str(c.value or "") for c in rows[ri])
        m = MM_YYYY.search(text)
        if m:
            cm, cy = int(m[1]), int(m[2])
            if 1 <= cm <= 12 and 2000 <= cy <= 2100:
                month, year = cm, cy
                break

    if year is None:
        print(f"  ⚠ Kein Abrechnungszeitraum gefunden: {os.path.basename(path)}")
        return []

    # Spalten aus Kopfzeile ermitteln
    col_ort = col_kommen = col_gehen = col_pause = col_notiz = None
    if header_row >= 0:
        for ci, cell in enumerate(rows[header_row]):
            v = str(cell.value or "").lower().strip()
            if "tag" in v:
                col_tag = ci
            if any(x in v for x in ("e-ort", "einsatzort", "ort")) and col_ort is None:
                col_ort = ci
            if any(x in v for x in ("kommen", "beginn", "start")) and col_kommen is None:
                col_kommen = ci
            if any(x in v for x in ("gehen", "ende")) or v == "bis" and col_gehen is None:
                col_gehen = ci
            if "pause" in v and col_pause is None:
                col_pause = ci
            if any(x in v for x in ("notiz", "bemerkung", "tätigkeit")) and col_notiz is None:
                col_notiz = ci

    col_kommen = col_kommen if col_kommen is not None else col_tag + 2
    col_gehen  = col_gehen  if col_gehen  is not None else col_tag + 3
    col_pause  = col_pause  if col_pause  is not None else col_tag + 4
    col_notiz  = col_notiz  if col_notiz  is not None else col_tag + 6

    entries = []
    seen = set()

    for ri in range(first_data_row, len(rows)):
        row = rows[ri]
        tag_str = cell_str(row, col_tag)
        dm = re.match(r'^(\d{1,2})', tag_str)
        if not dm:
            continue
        day = int(dm[1])
        if not (1 <= day <= 31):
            continue

        try:
            d = date(year, month, day)
            if d.day != day:
                continue
        except ValueError:
            continue

        kommen_str = cell_str(row, col_kommen)
        if not kommen_str:
            continue

        start = parse_time(d, kommen_str)
        if start is None:
            print(f"  ⚠ Z{ri+1}: Startzeit '{kommen_str}' nicht erkannt")
            continue

        gehen_str = cell_str(row, col_gehen)
        end = parse_time(d, gehen_str) if gehen_str else None
        if end and end < start:
            end += timedelta(days=1)

        brk = parse_break(cell_str(row, col_pause))
        note = cell_str(row, col_notiz)
        ort = cell_str(row, col_ort) if col_ort is not None else ""
        work_type = ort_to_work_type(ort)
        dt = day_type(d)

        dedup = f"{d.isoformat()}|{start.hour}:{start.minute:02d}"
        if dedup in seen:
            continue
        seen.add(dedup)

        entries.append({
            "id": stable_id(d.isoformat(), start),
            "date": d.isoformat(),
            "start_time": start.isoformat(),
            "end_time": end.isoformat() if end else None,
            "break_minutes": brk,
            "work_type": work_type,
            "day_type": dt,
            "note": note,
            "distance_km": None,
            "travel_minutes": 0,
            "employer_id": employer_id,
            "is_synced": 0,
            "created_at": datetime.now().isoformat(),
        })

    return entries

# ── Datenbank ────────────────────────────────────────────────────────────────

def find_db() -> Path | None:
    for p in DB_CANDIDATES:
        if p.exists():
            return p
    return None

def insert_entries(db_path: Path, entries: list):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    inserted = skipped = 0
    for e in entries:
        cur.execute("SELECT 1 FROM time_entries WHERE id = ?", (e["id"],))
        if cur.fetchone():
            skipped += 1
            continue
        cur.execute("""
            INSERT INTO time_entries
              (id, date, start_time, end_time, break_minutes, work_type, day_type,
               note, distance_km, travel_minutes, employer_id, is_synced, created_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            e["id"], e["date"], e["start_time"], e["end_time"],
            e["break_minutes"], e["work_type"], e["day_type"],
            e["note"], e["distance_km"], e["travel_minutes"],
            e["employer_id"], e["is_synced"], e["created_at"],
        ))
        inserted += 1
    con.commit()
    con.close()
    return inserted, skipped

# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    # Datenbank finden — optionaler Pfad als erstes Argument
    if len(sys.argv) > 1:
        db_path = Path(sys.argv[1])
        if not db_path.exists():
            print(f"Datenbank nicht gefunden: {db_path}")
            sys.exit(1)
    else:
        db_path = find_db()
    if db_path is None:
        print("Datenbank nicht gefunden. App einmal starten damit die DB angelegt wird,")
        print("dann: python import_stempeluhr.py C:\\Pfad\\zur\\zeiterfassung.db")
        print("\nGesucht in:")
        for p in DB_CANDIDATES:
            print(f"  {p}")
        sys.exit(1)
    print(f"Datenbank: {db_path}")

    # Employer-ID ermitteln
    con = sqlite3.connect(db_path)
    employers = con.execute("SELECT id, name FROM employers").fetchall()
    con.close()
    employer_id = None
    if employers:
        print("Arbeitgeber in der Datenbank:")
        for i, (eid, name) in enumerate(employers):
            print(f"  [{i}] {name}  (id={eid})")
        if len(employers) == 1:
            employer_id = employers[0][0]
            print(f"→ Verwende: {employers[0][1]}")
        else:
            idx = input("Welcher Arbeitgeber? Nummer eingeben: ").strip()
            employer_id = employers[int(idx)][0]

    # XLSX-Dateien einlesen
    files = sorted(glob.glob(os.path.join(XLSX_DIR, "*.xlsx")))
    if not files:
        print(f"Keine .xlsx-Dateien in: {XLSX_DIR}")
        sys.exit(1)
    print(f"\n{len(files)} Datei(en) gefunden.")

    total_new = total_skip = 0
    for f in files:
        print(f"\n→ {os.path.basename(f)}")
        entries = parse_xlsx(f, employer_id)
        if not entries:
            print("  (keine Einträge)")
            continue
        new, skip = insert_entries(db_path, entries)
        print(f"  {new} neu, {skip} bereits vorhanden")
        total_new += new
        total_skip += skip

    print(f"\nFertig: {total_new} neue Einträge, {total_skip} übersprungen.")

if __name__ == "__main__":
    main()
