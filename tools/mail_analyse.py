#!/usr/bin/env python3
"""
mail_analyse.py — Gurktaler E-Mail-Analyse für Zeiterfassung
============================================================
Analysiert Thunderbird-MBOX-Dateien, filtert E-Mails mit Bezug
zu Gurktaler-spezifischen Stichwörtern (aus der App-Whitelist),
summiert 2 Minuten pro E-Mail und erstellt SQL-INSERT-Statements
für die Zeiterfassung-SQLite-Datenbank.

Verwendung (auf dem Windows-PC mit Thunderbird):
  python mail_analyse.py
  python mail_analyse.py --from 2024-04 --to 2025-03
  python mail_analyse.py --mbox "C:/Users/.../Thunderbird/Profiles"
  python mail_analyse.py --keywords gurktaler mazerat underberg

Keywords:
  Standard: Gurktaler-Whitelist aus activity_tracking_service.dart
  (Produkte, Partner, Kunden, Rohstoffe — keine App-Namen)
  Wird automatisch aus der App-SharedPreferences gelesen, falls verfügbar.

Ausgabe:
  gurktaler_mails_YYYY-MM-DD.csv    Monatsübersicht
  gurktaler_insert_YYYY-MM-DD.sql   SQL für direkte DB-Einspielung
  gurktaler_bericht_YYYY-MM-DD.txt  Lesbares Protokoll
"""

import argparse
import json
import mailbox
import sqlite3
import sys
import uuid
import winreg
from collections import defaultdict
from datetime import datetime, timedelta
from email.header import decode_header as _decode_header
from email.utils import parsedate_to_datetime
from pathlib import Path


# ── Konfiguration ─────────────────────────────────────────────────────────────

MINUTES_PER_MAIL = 2
DEFAULT_START_HOUR = 8
WORK_TYPE = "other"
NOTE_TEMPLATE = "Mailbearbeitung Gurktaler ({n} Mails)"

# Gurktaler-spezifische Begriffe aus der App-Whitelist.
# App-Namen (chrome, firefox, word …) bewusst NICHT enthalten —
# diese passen für Aktivitätserkennung, aber nicht für E-Mail-Filter.
DEFAULT_KEYWORDS: list[str] = [
    # Produkte & Rohstoffe
    "gurktaler", "aqua", "mazerat", "destillat", "kräuter", "tank",
    "kalkulation", "garten",
    "thymian", "salbei", "oregano", "pfefferminze", "schokominze",
    "zitronenmelisse", "zitronengras", "zitronenverbene", "zitrus",
    "gurki", "sanddorn", "alpen",
    "alkohol", "likör", "aroma", "farbstoff",
    "kleinflasche", "kleinserie",
    # Partner & Kunden
    "burger", "spiller", "underberg", "stranner", "dudli", "maunz", "dencker",
    "mozart", "schlumberger", "top spirit", "pfau", "ruhdorfer", "jufa",
    "dom", "kalidz", "grames",
    # Prozesse & Termine (bewusst kein generisches "termin")
    "führung",
    # Lieferanten & Regionen
    "rüdesheim", "rheinberg", "heiligenstädter", "bio", "lacon",
]


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

def decode_str(value: str | bytes | None, charset: str | None = None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        for enc in (charset, "utf-8", "latin-1", "cp1252"):
            if enc:
                try:
                    return value.decode(enc, errors="replace")
                except (LookupError, UnicodeDecodeError):
                    pass
        return value.decode("ascii", errors="replace")
    return str(value)


def decode_header(header_value: str | None) -> str:
    if not header_value:
        return ""
    parts = []
    for fragment, charset in _decode_header(header_value):
        parts.append(decode_str(fragment, charset))
    return " ".join(parts)


def get_msg_date(msg) -> datetime | None:
    date_str = msg.get("Date", "")
    if not date_str:
        return None
    try:
        return parsedate_to_datetime(date_str)
    except Exception:
        pass
    for fmt in ("%a, %d %b %Y %H:%M:%S %z", "%d %b %Y %H:%M:%S %z"):
        try:
            return datetime.strptime(date_str.strip(), fmt)
        except ValueError:
            pass
    return None


def is_relevant(msg, keywords: list[str]) -> bool:
    """Prüft ob Von/An/CC/BCC/Betreff mindestens ein Keyword enthält."""
    fields = " ".join([
        decode_header(msg.get("From", "")),
        decode_header(msg.get("To", "")),
        decode_header(msg.get("Cc", "")),
        decode_header(msg.get("Bcc", "")),
        decode_header(msg.get("Subject", "")),
    ]).lower()
    return any(kw.lower() in fields for kw in keywords)


def month_key(dt: datetime) -> str:
    return dt.strftime("%Y-%m")


def last_workday(year: int, month: int) -> datetime:
    # letzter Tag des Monats, dann rückwärts bis Werktag
    d = datetime(year, month + 1, 1) - timedelta(days=1) if month < 12 \
        else datetime(year, 12, 31)
    while d.weekday() >= 5:
        d -= timedelta(days=1)
    return d


def deterministic_uuid(employer_id: str, month: str) -> str:
    namespace = uuid.UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
    return str(uuid.uuid5(namespace, f"mail:{employer_id}:{month}"))


# ── Whitelist aus App-SharedPreferences laden ─────────────────────────────────

def load_whitelist_from_app() -> list[str] | None:
    """
    Versucht die Whitelist aus den SharedPreferences der Zeiterfassung-App
    zu lesen. Speicherort (Windows): JSON-Datei im AppData-Verzeichnis
    oder Windows-Registry (shared_preferences_windows).
    Gibt None zurück wenn nicht gefunden.
    """
    home = Path.home()

    # shared_preferences_windows speichert als JSON-Datei
    json_candidates = [
        home / "AppData" / "Roaming" / "com.example.zeiterfassung" / "shared_preferences.json",
        home / "AppData" / "Local"   / "com.example.zeiterfassung" / "shared_preferences.json",
        home / "AppData" / "Roaming" / "Zeiterfassung" / "shared_preferences.json",
    ]
    for p in json_candidates:
        if p.exists():
            try:
                data = json.loads(p.read_text(encoding="utf-8"))
                wl = data.get("activity_whitelist")
                if isinstance(wl, list) and wl:
                    return [str(k) for k in wl]
            except Exception:
                pass

    # Fallback: Windows Registry
    try:
        reg_paths = [
            r"SOFTWARE\com.example.zeiterfassung",
            r"SOFTWARE\Zeiterfassung",
        ]
        for rp in reg_paths:
            try:
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, rp)
                val, _ = winreg.QueryValueEx(key, "activity_whitelist")
                winreg.CloseKey(key)
                parsed = json.loads(val) if isinstance(val, str) else val
                if isinstance(parsed, list) and parsed:
                    return [str(k) for k in parsed]
            except FileNotFoundError:
                pass
    except ImportError:
        pass   # kein winreg (nicht Windows)
    except Exception:
        pass

    return None


def resolve_keywords(cli_keywords: list[str] | None) -> list[str]:
    """
    Bestimmt die endgültige Keyword-Liste:
    1. --keywords CLI-Argument (überschreibt alles)
    2. App-SharedPreferences (nur Gurktaler-Begriffe, App-Namen gefiltert)
    3. DEFAULT_KEYWORDS
    """
    if cli_keywords:
        return [k.strip().lower() for k in cli_keywords if k.strip()]

    app_wl = load_whitelist_from_app()
    if app_wl:
        # App-Namen und generische Begriffe herausfiltern
        app_noise = {
            "chrome", "firefox", "edge", "opera", "brave",
            "word", "excel", "powerpoint", "libreoffice", "writer", "calc", "impress",
            "acrobat", "foxit", "sumatra", "outlook", "thunderbird",
            "teams", "zoom", "slack",
            "termin",   # zu generisch für E-Mail-Filter
        }
        filtered = [k for k in app_wl if k.lower() not in app_noise]
        if filtered:
            print(f"  Whitelist aus App geladen ({len(filtered)} Begriffe, "
                  f"{len(app_wl) - len(filtered)} App-Namen entfernt)")
            return [k.lower() for k in filtered]

    print(f"  Standard-Keywords verwendet ({len(DEFAULT_KEYWORDS)} Begriffe)")
    return DEFAULT_KEYWORDS


# ── Thunderbird-Dateierkennung ────────────────────────────────────────────────

def find_thunderbird_profiles() -> list[Path]:
    home = Path.home()
    candidates = [
        home / "AppData" / "Roaming" / "Thunderbird" / "Profiles",
        home / "AppData" / "Local"   / "Thunderbird" / "Profiles",
        home / ".thunderbird",
        home / "Library" / "Thunderbird" / "Profiles",
    ]
    return [p for p in candidates if p.exists()]


def find_mbox_files(roots: list[Path]) -> list[Path]:
    result = []
    for root in roots:
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix in (".msf", ".dat", ".index", ".sqlite", ".log"):
                continue
            try:
                if path.stat().st_size < 1024:
                    continue
                with open(path, "rb") as fh:
                    if fh.read(5) == b"From ":
                        result.append(path)
            except (OSError, PermissionError):
                pass
    return result


# ── Analyse ───────────────────────────────────────────────────────────────────

def analyse_mbox(path: Path, keywords: list[str],
                 from_month: str | None, to_month: str | None) -> dict[str, list[str]]:
    results: dict[str, list[str]] = defaultdict(list)
    try:
        mbox = mailbox.mbox(str(path))
    except Exception as exc:
        print(f"  [Warnung] {path.name}: {exc}", file=sys.stderr)
        return results

    count = total_relevant = 0
    for msg in mbox:
        count += 1
        if not is_relevant(msg, keywords):
            continue
        dt = get_msg_date(msg)
        if dt is None:
            continue
        mk = month_key(dt)
        if from_month and mk < from_month:
            continue
        if to_month and mk > to_month:
            continue
        subject = decode_header(msg.get("Subject", "(kein Betreff)"))
        results[mk].append(subject[:100])
        total_relevant += 1

    print(f"  {path.name:<40}  {count:>5} Mails,  {total_relevant:>4} relevant")
    return results


# ── DB-Zugriff ────────────────────────────────────────────────────────────────

def find_db_path() -> Path | None:
    home = Path.home()
    candidates = [
        home / "AppData" / "Roaming" / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
        home / "AppData" / "Local"   / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
        home / ".local" / "share" / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
    ]
    return next((p for p in candidates if p.exists()), None)


def get_employers_from_db(db_path: Path) -> list[dict]:
    try:
        conn = sqlite3.connect(str(db_path))
        cur = conn.execute("SELECT id, name FROM employers ORDER BY name")
        employers = [{"id": row[0], "name": row[1]} for row in cur.fetchall()]
        conn.close()
        return employers
    except Exception as exc:
        print(f"[Warnung] DB-Zugriff: {exc}", file=sys.stderr)
        return []


# ── SQL-Generierung ───────────────────────────────────────────────────────────

def build_sql(monthly: dict[str, int], employer_id: str) -> list[str]:
    now = datetime.now().isoformat(timespec="milliseconds")
    statements = []
    for mk in sorted(monthly):
        year, month = int(mk[:4]), int(mk[5:])
        n_mails  = monthly[mk]
        minutes  = n_mails * MINUTES_PER_MAIL
        wd       = last_workday(year, month)
        start_dt = wd.replace(hour=DEFAULT_START_HOUR, minute=0, second=0, microsecond=0)
        end_dt   = start_dt + timedelta(minutes=minutes)
        entry_id = deterministic_uuid(employer_id, mk)
        note     = NOTE_TEMPLATE.format(n=n_mails)

        statements.append(
            f"INSERT OR REPLACE INTO time_entries "
            f"(id, date, start_time, end_time, break_minutes, work_type, day_type, "
            f"note, travel_minutes, employer_id, is_special_hours, is_synced, created_at) VALUES ("
            f"'{entry_id}', "
            f"'{wd.strftime('%Y-%m-%d')}', "
            f"'{start_dt.isoformat(timespec='milliseconds')}', "
            f"'{end_dt.isoformat(timespec='milliseconds')}', "
            f"0, '{WORK_TYPE}', 'workday', '{note}', "
            f"0, '{employer_id}', 0, 0, '{now}');"
        )
    return statements


# ── Ausgabe ───────────────────────────────────────────────────────────────────

def print_summary(monthly: dict[str, int], keywords: list[str]) -> None:
    print()
    print("=" * 58)
    print(f"  ERGEBNIS  ·  {MINUTES_PER_MAIL} Min/Mail  ·  {len(keywords)} Keywords")
    print("=" * 58)
    print(f"  {'Monat':<12} {'Mails':>6}  {'Minuten':>8}  {'Stunden':>8}")
    print("  " + "-" * 40)
    total_mails = total_min = 0
    for mk in sorted(monthly):
        n = monthly[mk]
        m = n * MINUTES_PER_MAIL
        print(f"  {mk:<12} {n:>6}  {m:>8}  {m/60:>7.2f}h")
        total_mails += n
        total_min += m
    print("  " + "-" * 40)
    print(f"  {'GESAMT':<12} {total_mails:>6}  {total_min:>8}  {total_min/60:>7.2f}h")
    print()


def save_csv(monthly: dict[str, int], outfile: Path) -> None:
    with open(outfile, "w", encoding="utf-8-sig") as f:
        f.write("Monat;Anzahl Mails;Minuten;Stunden\n")
        for mk in sorted(monthly):
            n = monthly[mk]
            m = n * MINUTES_PER_MAIL
            f.write(f"{mk};{n};{m};{m/60:.2f}\n")
        total_mails = sum(monthly.values())
        total_min = total_mails * MINUTES_PER_MAIL
        f.write(f"GESAMT;{total_mails};{total_min};{total_min/60:.2f}\n")
    print(f"CSV gespeichert:  {outfile}")


def save_sql(statements: list[str], monthly: dict[str, int],
             employer_name: str, outfile: Path) -> None:
    with open(outfile, "w", encoding="utf-8") as f:
        f.write("-- Gurktaler Mailbearbeitung — Zeiterfassung Import\n")
        f.write(f"-- Erstellt: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        f.write(f"-- Arbeitgeber: {employer_name}\n")
        f.write(f"-- {MINUTES_PER_MAIL} Minuten pro E-Mail\n")
        f.write("--\n-- Einspielung: sqlite3 zeiterfassung.db < diese_datei.sql\n\n")
        for mk in sorted(monthly):
            n = monthly[mk]
            m = n * MINUTES_PER_MAIL
            f.write(f"-- {mk}:  {n} Mails  →  {m} Min  ({m/60:.2f}h)\n")
        f.write("\n")
        for stmt in statements:
            f.write(stmt + "\n")
    print(f"SQL gespeichert:  {outfile}")


def save_txt(monthly: dict[str, int], employer_name: str,
             keywords: list[str], outfile: Path) -> None:
    with open(outfile, "w", encoding="utf-8") as f:
        f.write("MAILBEARBEITUNG GURKTALER — ZEITERFASSUNG\n")
        f.write(f"Erstellt: {datetime.now().strftime('%d.%m.%Y %H:%M')}\n")
        f.write(f"Arbeitgeber: {employer_name}\n")
        f.write(f"Minuten pro E-Mail: {MINUTES_PER_MAIL}\n")
        f.write(f"Keywords ({len(keywords)}): {', '.join(keywords)}\n\n")
        f.write(f"{'Monat':<14} {'Mails':>6}  {'Minuten':>9}  {'Stunden':>9}  Notiz\n")
        f.write("-" * 72 + "\n")
        total_mails = total_min = 0
        for mk in sorted(monthly):
            year, month_num = int(mk[:4]), int(mk[5:])
            month_name = datetime(year, month_num, 1).strftime("%B %Y")
            n = monthly[mk]
            m = n * MINUTES_PER_MAIL
            f.write(f"{month_name:<14} {n:>6}  {m:>9}  {m/60:>8.2f}h  "
                    f"{NOTE_TEMPLATE.format(n=n)}\n")
            total_mails += n
            total_min += m
        f.write("-" * 72 + "\n")
        f.write(f"{'GESAMT':<14} {total_mails:>6}  {total_min:>9}  {total_min/60:>8.2f}h\n")
    print(f"Protokoll:        {outfile}")


# ── Hauptprogramm ─────────────────────────────────────────────────────────────

def main():
    global MINUTES_PER_MAIL
    parser = argparse.ArgumentParser(
        description="Gurktaler E-Mail-Analyse → Zeiterfassung SQL-Import",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--mbox", nargs="+", metavar="PFAD",
        help="MBOX-Datei(en) oder Thunderbird-Profilordner (Standard: auto)")
    parser.add_argument("--keywords", nargs="+", metavar="WORT",
        help="Suchbegriffe (Standard: Gurktaler-Whitelist aus der App)")
    parser.add_argument("--from", dest="from_month", metavar="YYYY-MM",
        help="Nur Mails ab diesem Monat")
    parser.add_argument("--to", dest="to_month", metavar="YYYY-MM",
        help="Nur Mails bis einschließlich diesem Monat")
    parser.add_argument("--employer-id", metavar="UUID",
        help="Arbeitgeber-UUID (wird sonst aus der DB gelesen)")
    parser.add_argument("--db", metavar="PFAD",
        help="Pfad zur zeiterfassung.db (Standard: auto)")
    parser.add_argument("--minutes", type=int, default=MINUTES_PER_MAIL,
        help=f"Minuten pro E-Mail (Standard: {MINUTES_PER_MAIL})")
    args = parser.parse_args()
    MINUTES_PER_MAIL = args.minutes

    print("=" * 58)
    print("  Gurktaler E-Mail-Analyse für Zeiterfassung")
    print("=" * 58)

    # ── Keywords ──────────────────────────────────────────────────────────────
    print("\nKeywords:")
    keywords = resolve_keywords(args.keywords)
    print(f"  Aktiv: {', '.join(keywords[:8])}{'…' if len(keywords) > 8 else ''}")

    # ── MBOX-Dateien ──────────────────────────────────────────────────────────
    mbox_paths: list[Path] = []
    if args.mbox:
        for p in args.mbox:
            fp = Path(p)
            if fp.is_dir():
                found = find_mbox_files([fp])
                print(f"\n{fp}: {len(found)} MBOX-Dateien")
                mbox_paths.extend(found)
            elif fp.is_file():
                mbox_paths.append(fp)
            else:
                print(f"[Warnung] Nicht gefunden: {fp}", file=sys.stderr)
    else:
        profiles = find_thunderbird_profiles()
        if not profiles:
            print("\n[Fehler] Kein Thunderbird-Profil gefunden.")
            print("  Bitte angeben: --mbox <Pfad>")
            sys.exit(1)
        print(f"\nThunderbird-Profile: {[str(p) for p in profiles]}")
        mbox_paths = find_mbox_files(profiles)
        print(f"  {len(mbox_paths)} MBOX-Dateien gefunden")

    if not mbox_paths:
        print("[Fehler] Keine MBOX-Dateien gefunden.")
        sys.exit(1)

    # ── Analyse ───────────────────────────────────────────────────────────────
    print(f"\nAnalysiere{f'  (ab {args.from_month})' if args.from_month else ''}"
          f"{f'  (bis {args.to_month})' if args.to_month else ''}:")
    all_monthly: dict[str, list[str]] = defaultdict(list)
    for path in mbox_paths:
        for mk, subjects in analyse_mbox(path, keywords, args.from_month, args.to_month).items():
            all_monthly[mk].extend(subjects)

    if not all_monthly:
        print("\nKeine passenden E-Mails gefunden.")
        print("  Tipp: --keywords mit eigenen Begriffen oder --mbox prüfen.")
        sys.exit(0)

    monthly_counts: dict[str, int] = {mk: len(v) for mk, v in all_monthly.items()}
    print_summary(monthly_counts, keywords)

    # ── Arbeitgeber-ID ────────────────────────────────────────────────────────
    employer_id = args.employer_id
    employer_name = "Gurktaler"
    db_path: Path | None = Path(args.db) if args.db else find_db_path()

    if db_path and db_path.exists():
        print(f"Zeiterfassung-DB: {db_path}")
        employers = get_employers_from_db(db_path)
        if employers:
            gurk = [e for e in employers if "gurktaler" in e["name"].lower()]
            if len(gurk) == 1 and not employer_id:
                employer_id   = gurk[0]["id"]
                employer_name = gurk[0]["name"]
                print(f"Arbeitgeber:      {employer_name}")
            elif not employer_id:
                print("\nArbeitgeber:")
                for i, e in enumerate(employers):
                    print(f"  [{i}] {e['name']}")
                idx = input("Nummer: ").strip()
                try:
                    employer_id   = employers[int(idx)]["id"]
                    employer_name = employers[int(idx)]["name"]
                except (ValueError, IndexError):
                    employer_id = ""
    else:
        if not employer_id:
            print("\n[Hinweis] DB nicht gefunden — SQL ohne employer_id.")
            print("  Alternativ: --db <Pfad> oder --employer-id <UUID>\n")
            employer_id = ""

    # ── Dateien speichern ─────────────────────────────────────────────────────
    today = datetime.now().strftime("%Y-%m-%d")
    save_csv(monthly_counts, Path(f"gurktaler_mails_{today}.csv"))
    save_txt(monthly_counts, employer_name, keywords, Path(f"gurktaler_bericht_{today}.txt"))

    if employer_id:
        statements = build_sql(monthly_counts, employer_id)
        save_sql(statements, monthly_counts, employer_name,
                 Path(f"gurktaler_insert_{today}.sql"))
    else:
        print("[Info] Kein Arbeitgeber → SQL übersprungen")

    # ── Details ───────────────────────────────────────────────────────────────
    show = input("\nBetreffzeilen anzeigen? [j/N] ").strip().lower()
    if show == "j":
        for mk in sorted(all_monthly):
            print(f"\n  {mk}  ({len(all_monthly[mk])} Mails):")
            for subj in sorted(set(all_monthly[mk])):
                print(f"    · {subj}")

    # ── Direkter DB-Import ────────────────────────────────────────────────────
    if employer_id and db_path and db_path.exists():
        do_import = input(
            f"\nSQL direkt in DB einspiele? [{db_path.name}] [j/N] "
        ).strip().lower()
        if do_import == "j":
            try:
                conn = sqlite3.connect(str(db_path))
                for stmt in build_sql(monthly_counts, employer_id):
                    conn.execute(stmt)
                conn.commit()
                conn.close()
                print(f"  {len(monthly_counts)} Einträge geschrieben.")
                print("  Zeiterfassung-App neu starten.")
            except Exception as exc:
                print(f"[Fehler] {exc}", file=sys.stderr)

    print("\nFertig.")


if __name__ == "__main__":
    main()
