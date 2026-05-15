#!/usr/bin/env python3
"""
mail_analyse.py — Gurktaler E-Mail-Analyse für Zeiterfassung
============================================================
Analysiert Thunderbird-MBOX-Dateien, filtert E-Mails mit Bezug
zu einem Stichwort (Standard: "gurktaler"), summiert 2 Minuten
pro E-Mail und erstellt SQL-INSERT-Statements für die
Zeiterfassung-SQLite-Datenbank.

Verwendung (auf dem Windows-PC mit Thunderbird):
  python mail_analyse.py
  python mail_analyse.py --mbox "C:/Users/.../Thunderbird/..." --keyword gurktaler
  python mail_analyse.py --mbox pfad1 pfad2  --from 2024-04 --to 2025-03

Ausgabe:
  - Tabellarische Auswertung in der Konsole
  - gurktaler_mails_YYYY-MM-DD.csv   (Monatsübersicht)
  - gurktaler_insert_YYYY-MM-DD.sql  (SQL für direkte DB-Einspielung)
  - gurktaler_insert_YYYY-MM-DD.txt  (lesbares Protokoll)
"""

import argparse
import mailbox
import os
import re
import sqlite3
import sys
import uuid
from collections import defaultdict
from datetime import datetime, timedelta
from email.header import decode_header as _decode_header
from email.utils import parsedate_to_datetime
from pathlib import Path


# ── Konfiguration ─────────────────────────────────────────────────────────────

MINUTES_PER_MAIL = 2
DEFAULT_START_HOUR = 8   # Tagesbeginn für synthetischen Eintrag
WORK_TYPE = "other"      # Tätigkeitsart in der DB
NOTE_TEMPLATE = "Mailbearbeitung Gurktaler ({n} Mails)"


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

def decode_str(value: str | bytes | None, charset: str | None = None) -> str:
    """Dekodiert einen E-Mail-Header-Wert sicher zu einem Unicode-String."""
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
    """Dekodiert einen codierten E-Mail-Header vollständig."""
    if not header_value:
        return ""
    parts = []
    for fragment, charset in _decode_header(header_value):
        parts.append(decode_str(fragment, charset))
    return " ".join(parts)


def get_msg_date(msg) -> datetime | None:
    """Extrahiert das Datum einer E-Mail als datetime-Objekt."""
    date_str = msg.get("Date", "")
    if not date_str:
        return None
    try:
        return parsedate_to_datetime(date_str)
    except Exception:
        pass
    # Fallback: rohe Datumsformate
    for fmt in ("%a, %d %b %Y %H:%M:%S %z", "%d %b %Y %H:%M:%S %z"):
        try:
            return datetime.strptime(date_str.strip(), fmt)
        except ValueError:
            pass
    return None


def is_relevant(msg, keyword: str) -> bool:
    """Prüft ob eine E-Mail das Keyword in Von/An/CC/BCC/Betreff enthält."""
    kw = keyword.lower()
    fields = [
        decode_header(msg.get("From", "")),
        decode_header(msg.get("To", "")),
        decode_header(msg.get("Cc", "")),
        decode_header(msg.get("Bcc", "")),
        decode_header(msg.get("Subject", "")),
    ]
    return any(kw in f.lower() for f in fields)


def month_key(dt: datetime) -> str:
    """Gibt einen sortierbaren Monat-Schlüssel zurück: 'YYYY-MM'."""
    return dt.strftime("%Y-%m")


def first_workday(year: int, month: int) -> datetime:
    """Gibt den ersten Werktag (Mo–Fr) des Monats zurück."""
    d = datetime(year, month, 1)
    while d.weekday() >= 5:   # 5=Sa, 6=So
        d += timedelta(days=1)
    return d


def deterministic_uuid(employer_id: str, month: str) -> str:
    """Erzeugt eine stabile UUID für einen monatlichen Mailbearbeitungs-Eintrag."""
    namespace = uuid.UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
    key = f"mail:{employer_id}:{month}"
    return str(uuid.uuid5(namespace, key))


# ── Thunderbird-Dateierkennung ────────────────────────────────────────────────

def find_thunderbird_profiles() -> list[Path]:
    """Sucht Thunderbird-Profilordner auf Windows, Linux und macOS."""
    candidates = []
    home = Path.home()
    # Windows
    candidates += [
        home / "AppData" / "Roaming" / "Thunderbird" / "Profiles",
        home / "AppData" / "Local" / "Thunderbird" / "Profiles",
    ]
    # Linux
    candidates += [home / ".thunderbird"]
    # macOS
    candidates += [home / "Library" / "Thunderbird" / "Profiles"]

    profiles = []
    for base in candidates:
        if base.exists():
            profiles.append(base)
    return profiles


def find_mbox_files(roots: list[Path]) -> list[Path]:
    """Findet alle MBOX-Dateien rekursiv unterhalb der übergebenen Pfade."""
    mbox_files = []
    for root in roots:
        for path in root.rglob("*"):
            if path.is_file() and not path.suffix in (".msf", ".dat", ".index"):
                try:
                    size = path.stat().st_size
                    if size < 1024:
                        continue
                    # MBOX beginnt mit "From " (with trailing space)
                    with open(path, "rb") as fh:
                        header = fh.read(5)
                    if header == b"From ":
                        mbox_files.append(path)
                except (OSError, PermissionError):
                    pass
    return mbox_files


# ── Analyse ───────────────────────────────────────────────────────────────────

def analyse_mbox(path: Path, keyword: str,
                 from_month: str | None, to_month: str | None) -> dict[str, list[str]]:
    """
    Liest eine MBOX-Datei und gibt ein Dict {monat: [betreff, ...]} zurück.
    """
    results: dict[str, list[str]] = defaultdict(list)
    try:
        mbox = mailbox.mbox(str(path))
    except Exception as exc:
        print(f"  [Warnung] {path.name}: {exc}", file=sys.stderr)
        return results

    count = total_relevant = 0
    for msg in mbox:
        count += 1
        if not is_relevant(msg, keyword):
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


# ── DB-Abfrage ────────────────────────────────────────────────────────────────

def find_db_path() -> Path | None:
    """Versucht die Zeiterfassung-SQLite-DB auf dem lokalen PC zu finden."""
    home = Path.home()
    candidates = [
        # Windows (Flutter / sqflite)
        home / "AppData" / "Roaming" / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
        home / "AppData" / "Local" / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
        # Linux
        home / ".local" / "share" / "com.example.zeiterfassung" / "databases" / "zeiterfassung.db",
    ]
    for p in candidates:
        if p.exists():
            return p
    return None


def get_employers_from_db(db_path: Path) -> list[dict]:
    """Liest Arbeitgeber aus der Zeiterfassung-DB."""
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
    """Erstellt idempotente INSERT OR REPLACE-Statements."""
    now = datetime.now().isoformat(timespec="milliseconds")
    statements = []

    for mk in sorted(monthly):
        year, month = int(mk[:4]), int(mk[5:])
        n_mails = monthly[mk]
        minutes = n_mails * MINUTES_PER_MAIL

        wd = first_workday(year, month)
        start_dt = wd.replace(hour=DEFAULT_START_HOUR, minute=0, second=0, microsecond=0)
        end_dt   = start_dt + timedelta(minutes=minutes)

        entry_id = deterministic_uuid(employer_id, mk)
        date_str  = wd.strftime("%Y-%m-%d")
        start_str = start_dt.isoformat(timespec="milliseconds")
        end_str   = end_dt.isoformat(timespec="milliseconds")
        note      = NOTE_TEMPLATE.format(n=n_mails)

        sql = (
            f"INSERT OR REPLACE INTO time_entries "
            f"(id, date, start_time, end_time, break_minutes, work_type, day_type, "
            f"note, travel_minutes, employer_id, is_special_hours, is_synced, created_at) "
            f"VALUES ("
            f"'{entry_id}', "
            f"'{date_str}', "
            f"'{start_str}', "
            f"'{end_str}', "
            f"0, "
            f"'{WORK_TYPE}', "
            f"'workday', "
            f"'{note}', "
            f"0, "
            f"'{employer_id}', "
            f"0, 0, "
            f"'{now}'"
            f");"
        )
        statements.append(sql)

    return statements


# ── Ausgabe ───────────────────────────────────────────────────────────────────

def print_summary(monthly: dict[str, int], keyword: str) -> None:
    print()
    print("=" * 55)
    print(f"  ERGEBNIS  ·  Keyword: '{keyword}'  ·  {MINUTES_PER_MAIL} Min/Mail")
    print("=" * 55)
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


def save_sql(statements: list[str], outfile: Path, monthly: dict[str, int],
             employer_name: str) -> None:
    with open(outfile, "w", encoding="utf-8") as f:
        f.write("-- Gurktaler Mailbearbeitung — Zeiterfassung Import\n")
        f.write(f"-- Erstellt: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        f.write(f"-- Arbeitgeber: {employer_name}\n")
        f.write(f"-- {MINUTES_PER_MAIL} Minuten pro E-Mail\n")
        f.write("--\n")
        f.write("-- Einspielung: sqlite3 zeiterfassung.db < diese_datei.sql\n")
        f.write("-- ODER: DB Browser for SQLite → SQL ausführen\n")
        f.write("\n")
        for mk in sorted(monthly):
            n = monthly[mk]
            m = n * MINUTES_PER_MAIL
            f.write(f"-- {mk}:  {n} Mails  →  {m} Min  ({m/60:.2f}h)\n")
        f.write("\n")
        for stmt in statements:
            f.write(stmt + "\n")
    print(f"SQL gespeichert:  {outfile}")


def save_txt(monthly: dict[str, int], employer_name: str, outfile: Path) -> None:
    """Lesbare Zusammenfassung als Textdatei (für Unterlagen)."""
    with open(outfile, "w", encoding="utf-8") as f:
        f.write("MAILBEARBEITUNG GURKTALER — ZEITERFASSUNG\n")
        f.write(f"Erstellt: {datetime.now().strftime('%d.%m.%Y %H:%M')}\n")
        f.write(f"Arbeitgeber: {employer_name}\n")
        f.write(f"Minuten pro E-Mail: {MINUTES_PER_MAIL}\n\n")
        f.write(f"{'Monat':<14} {'Mails':>6}  {'Minuten':>9}  {'Stunden':>9}  Notiz\n")
        f.write("-" * 70 + "\n")
        total_mails = total_min = 0
        for mk in sorted(monthly):
            year, month_num = int(mk[:4]), int(mk[5:])
            month_name = datetime(year, month_num, 1).strftime("%B %Y")
            n = monthly[mk]
            m = n * MINUTES_PER_MAIL
            note = NOTE_TEMPLATE.format(n=n)
            f.write(f"{month_name:<14} {n:>6}  {m:>9}  {m/60:>8.2f}h  {note}\n")
            total_mails += n
            total_min += m
        f.write("-" * 70 + "\n")
        f.write(f"{'GESAMT':<14} {total_mails:>6}  {total_min:>9}  {total_min/60:>8.2f}h\n")
    print(f"Protokoll:        {outfile}")


# ── Hauptprogramm ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Gurktaler E-Mail-Analyse → Zeiterfassung SQL-Import"
    )
    parser.add_argument(
        "--mbox", nargs="+", metavar="PFAD",
        help="Pfad(e) zu MBOX-Datei(en) oder Thunderbird-Profilordner. "
             "Ohne Angabe: automatische Suche."
    )
    parser.add_argument(
        "--keyword", default="gurktaler",
        help="Suchbegriff in Von/An/CC/Betreff (Standard: gurktaler)"
    )
    parser.add_argument(
        "--from", dest="from_month", metavar="YYYY-MM",
        help="Nur Mails ab diesem Monat (z.B. 2024-04)"
    )
    parser.add_argument(
        "--to", dest="to_month", metavar="YYYY-MM",
        help="Nur Mails bis einschließlich diesem Monat (z.B. 2025-03)"
    )
    parser.add_argument(
        "--employer-id", metavar="UUID",
        help="Arbeitgeber-UUID aus der Zeiterfassung-DB (wird sonst abgefragt)"
    )
    parser.add_argument(
        "--db", metavar="PFAD",
        help="Pfad zur zeiterfassung.db (wird sonst automatisch gesucht)"
    )
    parser.add_argument(
        "--minutes", type=int, default=MINUTES_PER_MAIL,
        help=f"Minuten pro E-Mail (Standard: {MINUTES_PER_MAIL})"
    )
    args = parser.parse_args()

    global MINUTES_PER_MAIL
    MINUTES_PER_MAIL = args.minutes

    print("=" * 55)
    print("  Gurktaler E-Mail-Analyse für Zeiterfassung")
    print("=" * 55)

    # ── MBOX-Dateien finden ──────────────────────────────────────────────────
    mbox_paths: list[Path] = []
    if args.mbox:
        for p in args.mbox:
            fp = Path(p)
            if fp.is_dir():
                print(f"\nDurchsuche Verzeichnis: {fp}")
                found = find_mbox_files([fp])
                print(f"  {len(found)} MBOX-Dateien gefunden")
                mbox_paths.extend(found)
            elif fp.is_file():
                mbox_paths.append(fp)
            else:
                print(f"[Warnung] Pfad nicht gefunden: {fp}", file=sys.stderr)
    else:
        profiles = find_thunderbird_profiles()
        if not profiles:
            print("\n[Fehler] Kein Thunderbird-Profil gefunden.")
            print("  Bitte Pfad angeben: --mbox <Pfad>")
            sys.exit(1)
        print(f"\nThunderbird-Profile gefunden:")
        for p in profiles:
            print(f"  {p}")
        print("\nDurchsuche MBOX-Dateien...")
        mbox_paths = find_mbox_files(profiles)
        print(f"  {len(mbox_paths)} MBOX-Dateien gefunden")

    if not mbox_paths:
        print("[Fehler] Keine MBOX-Dateien gefunden.")
        sys.exit(1)

    # ── Analyse ──────────────────────────────────────────────────────────────
    print(f"\nAnalysiere  (Keyword: '{args.keyword}'):")
    all_monthly: dict[str, list[str]] = defaultdict(list)
    for path in mbox_paths:
        monthly = analyse_mbox(path, args.keyword, args.from_month, args.to_month)
        for mk, subjects in monthly.items():
            all_monthly[mk].extend(subjects)

    if not all_monthly:
        print(f"\nKeine E-Mails mit '{args.keyword}' gefunden.")
        if args.from_month or args.to_month:
            print(f"  Zeitraum: {args.from_month or 'Beginn'} – {args.to_month or 'Ende'}")
        sys.exit(0)

    # Monatliche Summen
    monthly_counts: dict[str, int] = {mk: len(v) for mk, v in all_monthly.items()}
    print_summary(monthly_counts, args.keyword)

    # ── Arbeitgeber-ID ermitteln ──────────────────────────────────────────────
    employer_id = args.employer_id
    employer_name = "Gurktaler (unbekannt)"

    db_path: Path | None = Path(args.db) if args.db else find_db_path()

    if db_path and db_path.exists():
        print(f"Zeiterfassung-DB: {db_path}")
        employers = get_employers_from_db(db_path)
        if employers:
            # Gurktaler-Treffer automatisch vorschlagen
            gurk_matches = [e for e in employers
                            if "gurktaler" in e["name"].lower()]
            if len(gurk_matches) == 1 and not employer_id:
                employer_id = gurk_matches[0]["id"]
                employer_name = gurk_matches[0]["name"]
                print(f"Arbeitgeber auto-erkannt: {employer_name}")
            elif not employer_id:
                print("\nArbeitgeber in der DB:")
                for i, e in enumerate(employers):
                    print(f"  [{i}] {e['name']}")
                    print(f"       ID: {e['id']}")
                choice = input("\nNummer des Arbeitgebers eingeben: ").strip()
                try:
                    idx = int(choice)
                    employer_id = employers[idx]["id"]
                    employer_name = employers[idx]["name"]
                except (ValueError, IndexError):
                    print("[Warnung] Ungültige Eingabe — SQL wird ohne employer_id erstellt")
                    employer_id = ""
            else:
                for e in employers:
                    if e["id"] == employer_id:
                        employer_name = e["name"]
                        break
    else:
        if not employer_id:
            print("\n[Hinweis] Zeiterfassung-DB nicht gefunden.")
            print("  SQL kann trotzdem erstellt werden, aber ohne Arbeitgeber-Zuordnung.")
            print("  Alternativ: --db <Pfad> oder --employer-id <UUID> angeben.\n")
            employer_id = employer_id or ""

    # ── Dateien speichern ─────────────────────────────────────────────────────
    today = datetime.now().strftime("%Y-%m-%d")
    out_dir = Path(".")

    csv_path = out_dir / f"gurktaler_mails_{today}.csv"
    sql_path = out_dir / f"gurktaler_insert_{today}.sql"
    txt_path = out_dir / f"gurktaler_bericht_{today}.txt"

    save_csv(monthly_counts, csv_path)

    if employer_id:
        statements = build_sql(monthly_counts, employer_id)
        save_sql(statements, sql_path, monthly_counts, employer_name)
    else:
        print("[Info] Kein Arbeitgeber — SQL nicht erstellt. "
              "Bitte --employer-id <UUID> angeben.")

    save_txt(monthly_counts, employer_name, txt_path)

    # ── Details auf Wunsch ────────────────────────────────────────────────────
    show = input("\nBetreffzeilen der gefundenen Mails anzeigen? [j/N] ").strip().lower()
    if show == "j":
        for mk in sorted(all_monthly):
            print(f"\n  {mk}  ({len(all_monthly[mk])} Mails):")
            for subj in all_monthly[mk]:
                print(f"    · {subj}")

    # ── Direkter DB-Import auf Wunsch ──────────────────────────────────────────
    if employer_id and db_path and db_path.exists():
        do_import = input(
            f"\nSQL direkt in die Zeiterfassung-DB einspiele? [{db_path.name}] [j/N] "
        ).strip().lower()
        if do_import == "j":
            try:
                conn = sqlite3.connect(str(db_path))
                statements = build_sql(monthly_counts, employer_id)
                for stmt in statements:
                    conn.execute(stmt)
                conn.commit()
                conn.close()
                print(f"  {len(statements)} Einträge erfolgreich in die DB geschrieben.")
                print("  Zeiterfassung-App neu starten, damit die Änderungen sichtbar sind.")
            except Exception as exc:
                print(f"[Fehler] DB-Import: {exc}", file=sys.stderr)

    print("\nFertig.")


if __name__ == "__main__":
    main()
