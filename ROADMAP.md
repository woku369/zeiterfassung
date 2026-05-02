# Zeiterfassung – Roadmap

> Automatisch gepflegt via `/roadmap`. Manuell aktualisieren nach größeren Änderungen.
> Letztes Update: 2026-05-01 – Arbeitgeber-Trennung, Abwesenheitstypen, Stempeluhr-Import

---

## Projekt-Übersicht

Arbeitszeiterfassung für Teilzeitarbeit an wechselnden Orten und Geräten.
Ziel: saubere Dokumentation der geleisteten Stunden gegenüber 8h/Woche Vertrag
für einen Kräutergarten-Betrieb (Gurk/Wien/Salzburg).

**Stack:** Flutter (Android + Windows) · SQLite (lokal) · Next.js + SQLite (NAS-Backend) · Tailscale (VPN-Sync)

**Hardware:**
| Gerät | Typ | OS | Einsatz |
|---|---|---|---|
| Homeoffice-PC | Desktop Win11/64 | Windows 11 | Hauptarbeitsplatz |
| Xiaomi Poco X7 Pro | Smartphone | HyperOS 3.0.5.0 (Android 16) | Mobil, GPS, Geofencing |
| Surface Pro 8 | Tablet/Laptop Win11/64 | Windows 11 | Mobiler Windows-Einsatz |
| Surface Pro 7 | Tablet/Laptop Win11/64 | Windows 11 | Büro Gurk |

---

## Erledigt

### v1.0 – Grundgerüst
- [x] Flutter-App: Android & Windows (gemeinsame Codebasis)
- [x] Lokale SQLite-Datenbank (`sqflite`)
- [x] Zeiteinträge: Stempeluhr (Ein/Aus), manuelle Erfassung, Bearbeitung, Löschen
- [x] Arbeitstypen: Homeoffice, Telefonat, Außer-Haus-Termin, Fahrt, Büro, Sonstiges
- [x] Tagtypen: Werktag, Samstag, Sonntag, Feiertag (österr. Feiertage vorberechnet)
- [x] GPS-Erfassung (Start/End-Koordinaten, km-Distanz)
- [x] XLSX-Export (Monatsbericht mit KW-Summen, Monatsumme, Formatierung)
- [x] Mehrere Arbeitgeber, Wochenstunden-Konfiguration
- [x] NAS-Sync via Tailscale + Next.js REST-API (Upsert, bidirektional)
- [x] API-Key-Authentifizierung (optional)
- [x] Next.js-Backend mit Docker-Support (Synology NAS)
- [x] Material 3, Dark Mode, DE/AT-Lokalisierung

### v1.1 – Automatische Erfassung
- [x] **Geofencing:** Konfigurierbare Standorte (Name, GPS, Radius 50–1000m, Arbeitstyp)
- [x] Haversine-Distanzberechnung, 20m Mindestbewegung vor neuem Check
- [x] Android-Benachrichtigungen beim Betreten/Verlassen von Zonen
- [x] GPS-Hintergrundtracking (`ACCESS_BACKGROUND_LOCATION`)
- [x] **IMAP-E-Mail-Sortierung:** Mails nach Absender/Empfänger in Ordner verschieben
- [x] Betreff-Schlüsselwörter (inkl. Re:/Fwd:-Thread-Erkennung)
- [x] IMAP-Verbindungstest, Ordner automatisch anlegen
- [x] Aktivitätszeitstempel aus gesendeten Mails extrahieren
- [x] **Windows Tray-Widget:** Service vorbereitet (`tray_service.dart`)
- [x] DB-Migration v1→v2 (tracked_locations, imap_config)

### v1.2 – Dokumentation & UX
- [x] **Handbuch-Tab** (5. Tab): Tailscale, NAS, Geofencing, IMAP, Windows-Tray, Multi-Gerät
- [x] Kollabierbare Sektionen mit Codeblöcken (Long-Press zum Kopieren)
- [x] Einstellungen: Abschnitt „Automatische Erfassung"

### v1.3 – Soll/Ist-Auswertung
- [x] **Wirtschaftsjahr-Tab** im Berichte-Screen (Monat | Soll | Ist | Diff | Kumuliert)
- [x] Wirtschaftsjahr konfigurierbar pro Arbeitgeber (Standard: April–März)
- [x] Jahresnavigation (WJ 2024/25, WJ 2025/26, …)
- [x] Farbkodierung: grün (ausgeglichen) · orange (Mehrarbeit) · rot (Minderstunden)
- [x] Zukünftige Monate werden grau/ausgegraut dargestellt
- [x] Soll-Berechnung: `weeklyHours × 4.33` (Monatsdurchschnitt)
- [x] DB-Migration v3: `fiscal_year_start_month` (employers), `subject_keywords` (imap_config)
- [x] Wirtschaftsjahr-Monat im Arbeitgeber-Dialog konfigurierbar

### v1.4 – Mehrarbeitgeber & Abwesenheiten
- [x] **Arbeitgeber-Trennung:** `employer_id` auf allen Einträgen, alle Abfragen gefiltert
- [x] `ChangeNotifierProxyProvider` – Einträge/Berichte wechseln reaktiv bei Arbeitgeberwechsel
- [x] **Abwesenheitstypen:** Urlaubstag, Krankenstandstag, Zeitausgleich
- [x] Abwesenheitseinträge: keine Zeiterfassung, zählen nicht als Arbeitszeit
- [x] Feiertag-Erkennung im Eintrag-Formular (Farbe, Name, Auto-Tagtyp)
- [x] Vordef. Standorte: Homeoffice Glantscha, Labegg, Brückl, Gurk (3 Standorte)
- [x] DB-Migration v4 (`travel_minutes`), v5 (`employer_id`)
- [x] **Stempeluhr 2.1 Import:** Format-Erkennung, Duplikatschutz (UUID v5), E-Ort→Arbeitstyp
- [x] Import-Periodenanzeige ("April 2026 – 22 Einträge")
- [x] **Python-Import-Script** (`import_stempeluhr.py`): direkt in SQLite schreiben, ohne App
- [x] Urlaubsstatistik im Wirtschaftsjahr-Report (Tage Urlaub/Krankenstand/ZA)

---

## Offen / In Arbeit

### Kurzfristig – Datenqualität
- [ ] **Tätigkeitsart-Konzept überarbeiten:** Aktuell vermischt WorkType Arbeitsort und Tätigkeit
  - Trennung in **Arbeitsort** (Homeoffice, Gurk, Außer Haus, Sonstiges) und **Tätigkeit** (Freitext + Projektzuordnung)
  - Bestehende Einträge per Skript migrieren
- [ ] **Korrektur-Script für importierte Einträge** (`fix_worktypes.py` liegt bereits vor):
  - `travel` ohne km/Minuten → `offsite` korrigieren
  - Gurk-Einträge identifizieren und sauber zuordnen
- [ ] Import-Script: Gurk/Außen/Mobil differenzierter mappen (nicht alles `offsite`)
- [ ] **Fahrzeit-Konzept klären:** Fahrzeit als separates Feld vs. eigener Eintragstyp

### Kurzfristig – Plattform
- [ ] **Windows-Platform aktivieren:** `flutter create --platforms=windows .` ausführen
- [ ] **Tray-Widget fertigstellen:** Auskommentierte Zeilen in `tray_service.dart` aktivieren, `assets/tray_icon.ico` hinzufügen
- [ ] IMAP: `subject_keywords`-Spalte in DB-Migration v3 ergänzen (für bestehende Installationen)

### Mittelfristig – Auswertung
- [ ] **Statistik/Auswertung optimieren:** Aufschlüsselung nach Arbeitsort, nicht nur nach Typ
- [ ] Jahresexport: alle Monate des Wirtschaftsjahres in einer XLSX-Datei
- [ ] **Telefonat-Tracking:** Anrufdauer bekannter Nummern erfassen, optional als Eintrag vorschlagen

### Mittelfristig – Optionales Activity Tracking (Konzept)

Ziel: Recherche- und Arbeitszeit die "nebenbei" passiert nachträglich dokumentierbar machen —
ohne dauerhaften Overhead, ohne Cloud, ohne Zwang.

**Funktionsprinzip:**
- Manuell aktivierbar per Button ("Recherche-Modus starten") in der App oder im Tray-Widget
- Während aktiv: lokales Protokoll von Fenster-Titeln + Zeitstempeln (Windows) bzw. App-Namen (Android)
- Idle-Erkennung: Protokoll pausiert nach X Minuten ohne Aktivität automatisch
- Am Ende: Timeline-Ansicht zeigt was wann aktiv war — Nutzer wählt relevante Blöcke aus
- Ausgewählte Blöcke werden als Zeiteintrag mit vorausgefüllter Notiz (Fenster-Titel) vorgeschlagen
- Alles lokal, nichts wird automatisch gespeichert oder gesendet

**Technische Umsetzung Windows:**
- Win32 API `GetForegroundWindow` + `GetWindowText` → aktiver Fenster-Titel alle 30s abfragen
- Lokale SQLite-Tabelle `activity_log` (start, end, title, app_name)
- Tray-Widget startet/stoppt das Tracking per Klick

**Technische Umsetzung Android:**
- `UsageStatsManager` → App-Nutzung mit Zeitstempeln (erfordert `PACKAGE_USAGE_STATS`-Permission)
- Weniger granular als Windows (nur App-Name, kein Dokument-Titel)

**Datenschutz / Kontrolle:**
- Kein Autostart, immer manuell aktivieren
- Protokoll wird nach Übernahme in Zeiteintrag gelöscht (oder auf Wunsch behalten)
- Browser-Tabs/URLs werden bewusst NICHT erfasst (zu sensitiv)

**Offene Fragen vor Implementierung:**
- [ ] Welche Apps/Fenster sollen ignoriert werden? (Whitelist/Blacklist)
- [ ] Minimale Aktivitätsdauer für Vorschlag (z.B. nur Blöcke > 5 Minuten)
- [ ] Soll die Timeline in der App oder als separater Screen erscheinen?
- [ ] **Kalender-Integration:** Google Calendar / Exchange-Termine als Zeiteinträge importieren
- [ ] Offline-Indikator: Anzeige wenn keine NAS-Verbindung

### Langfristig / Ideen
- [ ] E-Mail-Zeitstempel als automatische Aktivitätshinweise im Dashboard anzeigen
- [ ] IFTTT/Zapier-Webhook als alternativer Auslöser
- [ ] Mehrsprachigkeit (DE/EN)

---

## Architektur-Notizen

```
app/
  lib/
    models/          time_entry, employer, tracked_location, imap_config, work_type
    providers/       time_entry_provider, employer_provider, location_provider
    services/        sync_service, export_service, import_service,
                     gps_service, holiday_service, geofencing_service,
                     imap_service, tray_service
    screens/         home, entries, entry_form, reports, settings,
                     locations, imap, help
    database/        database_helper (SQLite v5)
  android/           ACCESS_BACKGROUND_LOCATION, POST_NOTIFICATIONS
  windows/           (noch nicht generiert – flutter create --platforms=windows .)

backend/
  pages/api/         health, entries/index, entries/sync, entries/[id]
  lib/               db.ts (SQLite + WAL), auth.ts (API-Key)

import_stempeluhr.py   Einmal-Import Stempeluhr 2.1 XLSX → SQLite (Python)
fix_worktypes.py       Korrektur-Script für falsch gemappte Arbeitstypen
```

**Datenbank-Versionen:**
- v1: `employers`, `time_entries`
- v2: + `tracked_locations`, `imap_config`
- v3: + `fiscal_year_start_month` (employers), `subject_keywords` (imap_config)
- v4: + `travel_minutes` (time_entries)
- v5: + `employer_id` (time_entries)

**Branches:**
- `main` – stabiler Stand (v1.2)
- `claude/add-call-tracking-FyBFV` – aktueller Entwicklungsstand (v1.4)

---

## Bekannte Einschränkungen

| Thema | Details |
|---|---|
| Arbeitstyp-Konzept | WorkType vermischt Arbeitsort und Tätigkeit – Redesign geplant (v1.5) |
| Stempeluhr-Import E-Ort | „Mobil" wurde initial als Fahrt importiert – Korrektur via `fix_worktypes.py` |
| Hintergrund-GPS Android | Erfordert „Immer erlauben" – Android 12+ zeigt separaten Dialog |
| HyperOS/MIUI Akkuoptimierung | Xiaomi/HyperOS beendet Hintergrunddienste aggressiv – App in Akkuoptimierung auf „Keine Einschränkungen" setzen |
| IMAP ohne SSL | Port 143 möglich, nicht empfohlen für produktive Nutzung |
| Windows Tray | Noch nicht fertig – Windows-Platform-Ordner fehlt |
| iOS | Nicht geplant – kein Geofencing im Hintergrund, kein Anruf-Tracking |
| Überstunden-Kalkulation | Bewusst nicht implementiert (keine automatischen Zuschläge) |
