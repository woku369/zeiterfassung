# Zeiterfassung – Roadmap

> Automatisch gepflegt via `/roadmap`. Manuell aktualisieren nach größeren Änderungen.
> Letztes Update: 2026-05-27 – v1.27 Auto-Pause + Timeline-Adopted + Geofencing/Backup-Bugfixes + Backup-Refactoring

---

## Projekt-Übersicht

Arbeitszeiterfassung für Teilzeitarbeit an wechselnden Orten und Geräten.
Ziel: saubere Dokumentation der geleisteten Stunden gegenüber 8h/Woche Vertrag
für einen Kräutergarten-Betrieb (Gurk/Wien/Salzburg).

**Stack:** Flutter (Android + Windows) · SQLite (lokal) · Node.js + SQLite (NAS-Backend) · Tailscale (VPN-Sync)

**Hardware:**
| Gerät | Typ | OS | Einsatz |
|---|---|---|---|
| Homeoffice-PC | Desktop Win11/64 | Windows 11 | Hauptarbeitsplatz |
| Xiaomi Poco X7 Pro | Smartphone | HyperOS 3.0.5.0 (Android 16) | Mobil, GPS, Geofencing |
| Surface Pro 8 | Tablet/Laptop Win11/64 | Windows 11 | Mobiler Windows-Einsatz |
| Surface Pro 7 | Tablet/Laptop Win11/64 | Windows 11 | Büro Gurk |
| Doogee U11 Pro | Tablet Android 16 | Android 16 | Außendienst-Tablet |

---

## Erledigt

### v1.27 – Auto-Pause § 11 AZG + Timeline-Adopted + Geofencing/Backup-Bugfixes

- [x] **Auto-Pause § 11 AZG beim Speichern:**
  - `entry_form_screen.dart`: bei Einträgen ≥6h Nettodauer + `break_minutes=0` (kein Homeoffice/Abwesenheit) wird automatisch `break_minutes=30` gesetzt und `autoPauseApplied=true` gemerkt
  - SnackBar nach dem Speichern: „Auto-Pause § 11 AZG: 30 Min. Pause eingetragen."
  - Bereits in `geofencing_background.dart` und `home_screen.dart` implementiert (Clock-out-Pfad); Eintragsformular war bisher ausgenommen

- [x] **Fahrzeit/Pause-Chips auf Eintragszeilen:**
  - `entries_screen.dart → _buildSubtitle()`: tealfarbener Chip „N min Fahrt" + lila Chip „N min Pause" in der Untertitelzeile
  - Redundanter Plaintext-Suffix für Fahrzeit entfernt (war doppelt)

- [x] **Retroaktive Auto-Pause (Einstellungen → Datenpflege):**
  - `DatabaseHelper.applyAutoPauseToHistorical()`: SQL-Abfrage aller Einträge mit `break_minutes=0, end_time IS NOT NULL, work_type NOT IN (homeoffice, vacation, sick, compensatoryLeave)`; Dart-seitige Prüfung ≥360 Minuten; Update `break_minutes=30, is_synced=0`
  - `settings_screen.dart`: neuer `_AutoPauseCard`-Button zwischen `_ForceResyncCard` und `_DedupCard`
  - Bestätigungsdialog erklärt Logik; nach Anwendung sofortiger Sync; SnackBar mit Anzahl aktualisierter Einträge

- [x] **Übernommene Vorschläge bleiben in Activity-Timeline sichtbar:**
  - `suggestion_provider.dart`: neues `_accepted`-Set + `accept(id)` + Persistenz via `SharedPreferences fusion_accepted_ids`; `adopted`-Getter gibt übernommene Vorschläge zurück
  - `activity_timeline_screen.dart`: `_acceptSuggestion()` ruft `SuggestionProvider.accept()` auf; Section rendert `sp.pending` + `sp.adopted` kombiniert
  - `_SuggestionCard` neuer `adopted`-Parameter: Opacity 0.50, Hintergrundfarbe `surfaceContainerLow`, Häkchen-Icon, Titel durchgestrichen, grüner „Übernommen"-Badge, keine Aktions-Buttons
  - Calls und Raw-Sessions hatten adopteten State bereits via `ActivityProvider._adoptedCallIds/SessionIds` (v1.18)

- [x] **Bugfixes v1.27:**
  - **3 Geofencing-Bugs:** Stale Auto-Entry-ID nach SKIP-bedingtem Clock-in-Abbruch → verhinderte Clock-out; `is_synced` bei Auto-Entries nicht auf 0 gesetzt → wurden nie gepusht; Exit-Gap-Detektion zählte auch SKIP-Zyklen mit
  - **GPS-Stream lautloser Tod + Doze-Mode:** GPS-Stream stirbt nach Doze-Pause ohne Benachrichtigung; Fix: Watchdog-Timer prüft ob Stream seit >5 Min keine Fixes liefert → Neustart; explizites Wakelock für GPS-Ticks
  - **SKIP-Log:** Diagnose-Log zeigt jetzt bei GPS-SKIP den blockierenden Eintrag (ID, Startzeit, Typ, Notiz) – erleichtert manuelle Fehlersuche
  - **Falsche EXIT-Notification nach geskipptem Clock-in:** Notification „Verlasse Zone" erschien auch wenn das zugehörige Clock-in übersprungen wurde. Fix: EXIT-Notification nur wenn `geofence_auto_entry_id` aktiv
  - **Backup Catch-up-Logik:** Geofencing-Service prüfte Backup-Fenster (02:00/01:30/01:00) nur im laufenden Tick → enge 30-s-Fenster wurden verpasst wenn Dienst schlief. Fix: „War die Zeit seit letztem Tick vergangen?" statt „Bin ich genau jetzt im Fenster?"
  - **Activity-Timeline Aquamail/App-Fragment-Problem:** Android `ACTIVITY_PAUSED`/`ACTIVITY_RESUMED` feuert auch bei internen Activity-Übergängen (z.B. E-Mail-Liste → E-Mail-Detail) → Session wird in Sub-Threshold-Fragmente aufgesplittet. Fix: `UsageStatsPlugin.kt` mergt Fragmente gleicher App mit Gap < 30 s vor Rückgabe an Dart
  - **GPS-SKIP dauerhaft (Poco X7 Pro im Gebäude):** `_kMaxAccuracyM` war 80.0 m → Zonenprüfung dauerhaft blockiert wenn GPS-Genauigkeit 100 m (Cell/WiFi-Fallback). Fix: Threshold auf 150.0 m erhöht (alle konfigurierten Zonen > 9 km entfernt – ausreichend präzise)
  - **Backup-Retry-Loop:** Keine Cooldown-Logik nach fehlgeschlagenem Backup → jede Minute erneuter Versuch. Fix: `backup_last_*_attempt`-Key in SharedPreferences; nächster Versuch erst nach 30 Min; Schlüssel wird bei Erfolg entfernt
  - **§ 68 EStG Freibetrag korrigiert:** `reports_screen.dart _kCeiling` war 360.0 → auf 400.0 geändert (gültig seit 1.1.2024); `help_screen.dart` entsprechend aktualisiert; Skill-Referenzdatei `sonderarbeitszeit-ho-reisen.md` um vollständige § 68-Sektion ergänzt
  - **Auto-Clock-in durch offenen Abwesenheitseintrag blockiert:** SKIP-Check prüfte `end_time IS NULL` ohne Typfilter — Urlaubs-/Krankenstand-/ZA-Einträge haben designbedingt kein `end_time` und blockierten jeden Auto-Clock-in dauerhaft. Fix: `work_type NOT IN ('vacation','sick','compensatoryLeave')` in der Query
  - **Backup-Fehlerursache im Log sichtbar + 30s Timeout:** `scheduledNasBackup` gab nur `bool` zurück; `catch (_)` verschluckte die Fehlerursache vollständig. Refactoring auf `(bool, String?)`: Timeout nach 30 s, HTTP-Statuscode + Body, Exception-Text werden geloggt
  - **Tägliches Backup an Sync gekoppelt:** `SyncProvider._runDailyBackupIfNeeded()` läuft nach jedem erfolgreichen Sync — zuverlässiger als Zeitfenster (02:00 Uhr) im Geofencing-Service. Monatliches/jährliches Backup bleibt im Geofencing-Service. Täglicher Backup-Block im Geofencing-Service entfernt.
  - **Auto-Pause-Nachtrags-Button entfernt:** Massenupdate historischer Einträge ohne Einzelkontrolle zu riskant. `_AutoPauseCard` aus Einstellungen und `applyAutoPauseToHistorical()` aus `DatabaseHelper` entfernt. Auto-Pause beim Speichern neuer Einträge bleibt.

---

### v1.26 – Geplante NAS-Backups + Sync-Datenintegrität

- [x] **Geplante automatische NAS-Backups (Poco X7 Pro → NAS):**
  - Täglich 02:00 → letzte 30 daily-Backups behalten
  - Monatlich 01:30 am 1. des Monats → nie löschen
  - Jährlich 01:00 am 1. des WJ-Startmonats → nie löschen
  - Läuft im Geofencing-Foreground-Service (kein separater Prozess nötig)
  - SharedPreferences trackt letzte Backup-Zeiten zur Deduplizierung

- [x] **NAS-Backup-Liste & Restore (alle Geräte):**
  - Einstellungen → NAS-Backups: Liste aller Backups (täglich/monatlich/jährlich)
  - Gruppiert nach Typ, mit Datum und Dateigröße
  - Wiederherstellen mit Bestätigungsdialog

- [x] **Server: Backup-Endpunkte:**
  - `POST /api/backup/scheduled` — typisiertes Backup + Rotation (daily×30)
  - `GET /api/backup/list` — Backup-Liste
  - `GET /api/backup/get?file=` — Backup abrufen (Path-Traversal-gesichert)

- [x] **Sync-Status-Chip im Home-Screen:**
  - Grün mit Uhrzeit wenn Sync < 2h
  - Rot „Sync ausstehend" wenn > 2h ohne Sync (bei konfiguriertem NAS)
  - `lastSyncAt` wird in SharedPreferences persistiert (überlebt App-Neustart)

- [x] **Kritischer Sync-Bug behoben:**
  - `updateEntry` hat `is_synced = 1` nicht zurückgesetzt → jede Bearbeitung nach erstem Sync wurde nie gepusht (Clock-out, Notiz, km, Pause)
  - Ursache seit Projektbeginn im Code; alle Geräte hatten abweichende Datenstände

- [x] **Vollständige Neusynchronisierung erzwingen (Einstellungen → Datenpflege):**
  - Neuer Button `_ForceResyncCard`: markiert alle lokalen `time_entries` mit `is_synced=0`
  - Anschließend sofortiger Sync → vollständiger Push aller Einträge ans NAS
  - Andere Geräte ziehen beim nächsten Sync den korrekten Stand
  - Behebt historische Diskrepanzen (z.B. KW 20: Poco 2:05h vs. Doogee 1:04h) die durch den pre-b16 `updateEntry`-Bug entstanden sind
  - Warndialog mit Hinweis: nur auf dem Gerät mit korrekten Daten ausführen

- [x] **Bugfixes v1.26:**
  - Backup-Timer in Geofencing-Service war nicht gecancelt → Timer-Leak beim `stop`-Event
  - `vacation_days_per_year` fehlte in `pushEmployers`-Binding (server.js)
  - Stale offene NAS-Einträge überschreiben lokal abgeschlossene nicht mehr

### v1.25 – Geofencing Auto-km + Sync-Bugfixes + Build-Nr. (DB v18)

- [x] **Geofencing Standard-km pro Zone (DB v18):**
  - Neues Feld `default_km` in `tracked_locations` – pro Zone konfigurierbar
  - Im Standort-Dialog: TextField „Standard-km bei Auto-Einstempeln"
  - Zone-Kachel zeigt km wenn gesetzt
  - Beim Auto-Clock-in: `distance_km` wird automatisch vorausgefüllt (kein leerer Eintrag mehr)

- [x] **So/FT-Pauschale: Jahressumme + Monatsdurchschnitt:**
  - Neue Summary-Zeile „Ø steuerfrei/Monat (N Monate)"
  - Prominente „Empfohlene Pauschale"-Anzeige im grünen Block mit §68-Limit-Hinweis
  - Erleichtert Verhandlung: Jahresdurchschnitt als konkreter Betrag sichtbar

- [x] **Bruttogehalt via NAS synchronisieren:**
  - `server.js`: `monthly_gross REAL` in CREATE TABLE + Migration + upsertEmployer
  - Einmalige Eingabe auf einem Gerät → alle Geräte erhalten den Wert via Sync
  - Fix: `vacation_days_per_year` fehlte ebenfalls im `pushEmployers`-Binding

- [x] **Build-Nr. in Einstellungen → Info:**
  - `package_info_plus` hinzugefügt
  - Zeigt „Version X.Y.Z · Build N" – Build-Nr. wird von `build.ps1` automatisch hochgezählt

- [x] **Bugfixes v1.25:**
  - **Kritisch:** Stale offene NAS-Einträge überschreiben lokal abgeschlossene nicht mehr – verhindert Phantom-Clock-ins nach Sync (z.B. Windows-Start nach Android-Absturz ohne Push)
  - `employer.dart`: `static final _kNoValue` → `static const Object _kNoValue` (Build-Fehler Dart-Konstante)

### v1.24 – Saisonmuster + So/FT-Pauschale + Arbeitsrecht-Bugfixes (DB v16/v17)

- [x] **Sa/So/Feiertag-Kennzeichnung automatisch + retroaktiv (DB v16):**
  - `HolidayService`: österreichische Feiertage (Gauss-Osterformel, 13 gesetzliche FT)
  - DB-Migration v16: alle bestehenden Einträge retroaktiv korrigiert (`day_type` = `saturday`/`sunday`/`holiday`/`workday`)
  - Neue Einträge: `DayType` wird beim Anlegen automatisch gesetzt (Clock-in, Formular, Geofencing)

- [x] **Saisonmuster-Karte im Wirtschaftsjahr-Tab:**
  - Balkendiagramm: Ø h/Woche pro Monat vs. Vertragssoll
  - Farbkodierung: blaugrau (< 50 %) → grün (≈ Soll) → orange (> Soll) → tiefrot (> 150 %)
  - Sa/So/FT-Marker (Anzahl Einträge je Monat)

- [x] **So/FT-Pauschale-Rechner (nur Gurktaler AG):**
  - § 68 EStG: So/FT-Zuschläge steuer- & SV-frei bis €400/Monat (seit 1.1.2024; davor €360)
  - Monatliche Aufschlüsselung + Deckel-Indikator (✓ / ⚠)
  - Jährlicher Gesamtvorteil DN (LSt + SV) + DG (SV)
  - Neues Feld `monthly_gross` (DB v17) in AG-Einstellungen für €-Berechnung

- [x] **XLSX Zuschläge-Sheet: monatliche Saisonübersicht:**
  - Neuer Argumentationsabschnitt: Ist-h, Ø h/Woche, So/FT-h pro Monat

- [x] **Bugfixes v1.24:**
  - Auto-Pause-Schwelle 5h → 6h (§ 11 AZG): geofencing_background.dart + home_screen.dart
  - Geofencing: kein Re-Clock-in nach Karenz-Rückkehr in selbe Zone – `returningFromCarenz`-Flag verhindert unnötiges Clock-out/Clock-in
  - `_autoClockOut`: SharedPreferences-Key erst nach erfolgreichem DB-Update entfernen (Retry-Sicherheit)
  - Geofencing date-Feld: ISO-8601-konformes Format mit Null-Padding statt `toIso8601String()`
  - Dark-Mode: hardcoded `Colors.black87`/`shade800`/`shade900` in entry_form, entries_screen, reports_screen ersetzt
  - DB `_create()`: `monthly_gross REAL`-Spalte war in CREATE TABLE vergessen (nur in Migration vorhanden)

### v1.23 – App-Icon + Kalender-Picker + Soll-Bereinigung + UX-Polishing

- [x] **App-Icon ersetzt (Android + Windows):**
  - Neues Icon: analoge Stoppuhr, weiß/silber/glassy (ChatGPT-generiert, 1254×1254 PNG)
  - Android: adaptive Icon (alle 5 Mipmap-Dichten mdpi–xxxhdpi, Foreground-Canvas 108dp, Safe-Zone 72dp)
  - Windows: `tray_icon.ico` mit 6 Größen (256/128/64/48/32/16 px)
  - SVG-Quelldatei `app/assets/icon_source.svg` als Referenz im Repo
  - `values/colors.xml`: `ic_launcher_background = #FFFFFF`

- [x] **Geofencing: Auto-Start bei Neuinstallation:**
  - `geofencing_active`-Key in SharedPreferences war nie gesetzt (null) → Geofencing war nach Neuinstallation inaktiv
  - Fix: in `app.dart._setupSync()` nach `lp.load()`: wenn Pref null + Standorte vorhanden → automatisch starten
  - Manuelle Ein-/Aus-Schaltung durch User bleibt weiterhin persistent (false/true wird nicht überschrieben)
  - Verifiziert: Gurk-Zone (500 m) → Auto-Clock-in + Auto-Clock-out nach 5 Min Karenz ✓ (2026-05-20)

- [x] **Kalender-Picker mit Eintragsindikator (`entry_calendar_picker.dart`):**
  - Ersetzt Standard-`showDatePicker` im Eintragsformular durch eigenen Dialog
  - Lädt Einträge aller Arbeitgeber für den angezeigten Monat aus der DB
  - Indikatoren pro Tag: **U** (Urlaub, blau) · **K** (Krankenstand, orange) · **ZA** (Zeitausgleich, grün) · **●** (sonstiger Eintrag, grau)
  - Monatsnavigation ← →, Heute-Ring, Ausgewählt-Füllung, Wochenenden gedimmt, Feiertage gedimmt
  - Legende am unteren Rand; Race-Condition bei schneller Navigation per Generation-Counter abgesichert
  - Nutzen: freie Werktage sofort erkennbar für Urlaubsplanung; Urlaub im Voraus eintragen

- [x] **Soll-Bereinigung um Abwesenheitstage (Urlaub, KS, ZA):**
  - Formel: `bereinigtesSoll = weeklyHours × 4,33 − absenceDays × (weeklyHours / 5)`
  - Bei 8 h/Woche: 1 Abwesenheitstag = 1,6 h Soll-Reduktion; 5 Tage (1 Woche) = 8 h → Monatssaldo 0
  - **Monatsbericht:** Soll-Zeile heißt bei Abwesenheiten „Soll (bereinigt)" mit Subtext `rawSoll − Reduktion Abw.`
  - **Wirtschaftsjahr-Tabelle:** pro Monat bereinigtes Soll; Monate mit Abwesenheiten zeigen `26,6h*` + Tooltip
  - **Gesamtzeile:** summiert bereinigte Monats-Solls statt `weeklyHours × 4,33 × 12`
  - `_SummaryRow` um optionalen `subtext`-Parameter erweitert

- [x] **Bugfixes v1.23:**
  - `entry_calendar_picker.dart`: Race Condition bei schneller Monatsnavigation – Generation-Counter verhindert, dass ältere DB-Abfragen neuere Ergebnisse überschreiben

### v1.22 – Activity-Pooling + Projekt-Aufschlüsselung (DB v14/v15)

- [x] **Projekt-Aufschlüsselung innerhalb eines Zeiteintrags (DB v14):**
  - Neue Tabelle `entry_project_splits (id, entry_id, project_id, minutes, created_at, updated_at)`
  - Eintrag-Formular: mehrere Projekt-Zeilen + Minutenfeld + Fortschrittsbalken (Budget-Bar)
  - Berichte-Screen: Projekt-Aufschlüsselung liest Splits; Fallback auf `project_id` für Altdaten
  - Sync: `getAllSplitsForSync()` → Payload + `upsertSplitsFromServer()` auf beiden Seiten
  - Backend: `entry_project_splits`-Tabelle in `db.ts` + Upsert-Logik in `sync.ts`

- [x] **Activity-Pooling über alle Geräte (DB v15):**
  - `ActivityLog`-Modell: neues Feld `device_id` (nullable), `copyWith()`, `toJson()`/`fromJson()`
  - DB v15: `ALTER TABLE activity_log ADD COLUMN device_id TEXT` + `is_synced INTEGER NOT NULL DEFAULT 0`
  - `ActivityTrackingService`: `_deviceName`-Feld + `setDeviceName()` – alle erzeugten Logs tragen Gerätenamen
  - `ActivityProvider`: Gerätename aus SharedPreferences laden (`Platform.localHostname` als Default); Android `loadSessions()` persistiert UsageStats in DB → Pool-Sicht aller Geräte
  - `ActivityTimelineScreen`: blauer `_DeviceChip` auf Session-Karten anderer Geräte
  - `SyncService`: `activity_logs` im Sync-Payload (Push unsynced, Pull von anderen Geräten, Mark synced)
  - Backend `db.ts`: `activity_log`-Tabelle mit `device_id`; `sync.ts`: Upsert + Pull-Filter (kein Echo an Absender)
  - Einstellungen: neues Feld „Gerätename" unter Aktivitäts-Tracking

- [x] **Zuschläge-Tab im Jahresbericht XLSX (nur Gurktaler AG):**
  - Neues Sheet „Zuschläge" wird automatisch in `exportYear()` eingefügt wenn `isSurchargeEmployer=true`
  - Aufteilung jedes Eintrags in Normal-/+50%/+100%-Stunden: Sa vor 13h = normal, Sa 13–20h = ×1.5, Sa/Sa nach 20h = ×2.0, So/Feiertag gesamt = ×2.0, Werktag nach 20h = ×2.0
  - Farbkodierung: hellgelb (+50%), hellrosa (+100%), weiß (normal)
  - Monatssummen + Jahressumme für alle Spalten
  - Argumentation-Sektion (lila): Soll vs. effektiv-gewichtet, Wochen-Äquivalent, Differenz zum 10h-Ziel, km/Fahrzeit-Summen, Hinweis auf § 68 EStG (400 €/Monat steuerfrei DN+DG, seit 1.1.2024)
  - Homeoffice-Einträge werden als „normal" geführt (kein Zuschlag per Vereinbarung)

- [x] **Geofencing-Bugfixes v1.22 (3 Root Causes):**
  - **EXIT für nie-betretene Zonen:** Exit-Block lief als Fallthrough wenn `wasInside=false && !measuredInside` → alle 6 Zonen starteten alle 5 Min Karenz-Timer. Fix: Exit-Block in `if (wasInside)` eingeschlossen
  - **CLOCK-IN blockiert bei Zonenwechsel während laufender Karenz:** `_autoClockIn` fand offenen Eintrag der alten Zone → „Bereits eingestempelt". Fix: beim ENTER laufende Karenz-Timer anderer Zonen abbrechen + sofort `_autoClockOut` aufrufen
  - **CLOCK-IN blockiert wenn alte Zone noch in `inside` steckt (kein Karenz-Timer):** Tritt auf wenn Nutzer direkt von Zone A zu Zone B fährt ohne Exit-Bestätigung abzuwarten (z.B. Brückl → Labegg). Fix: beim ENTER alle anderen Zonen aus `inside`/`exitConfirm` entfernen + immer `_autoClockOut` vor `_autoClockIn`

- [x] **Geofencing-Architektur-Entscheidung: Ein Standort pro Gelände:**
  - Gurk: 3 Einzelzonen (Büro Hemmaweg, Domplatz, Kräutergarten) auf **einen Standort „Gurktaler Gurk"** zusammengeführt, Radius 500 m
  - Begründung: GPS-Genauigkeit ~20–80 m, Exit-Puffer +80 m → Einzelzonen mit <300 m Abstand führen zu Überlappungen und Fehldetektionen
  - Unterstandort (Büro / Mazeration / Garten) wird nach Auto-Clock-in manuell im Eintrag ergänzt
  - Wien, Salzburg, sonstige Außentermine: bei Bedarf als eigene Standorte anlegen

- [x] **Wochensoll-Dialog vor Jahresbericht-Export:**
  - Vor dem Export erscheint ein Dialog „Wochensoll für WJ XX/XX" mit dem aktuellen Wert vorausgefüllt
  - Editierbar für historische Wirtschaftsjahre (z.B. WJ 24/25 = 4 h, WJ 25/26 = 8 h)
  - Ändert das gespeicherte Arbeitgeber-Profil nicht – gilt nur für diesen Export
  - Sobald ein neuer Wert vertraglich fixiert wird (10 h oder 12 h), wird er im Code fest verankert

- [x] **Bugfixes v1.22:**
  - `database_helper.dart`: `insertActivityLogs()` verwendete `ConflictAlgorithm.replace` → resettet `is_synced=0` bei jedem `loadSessions()`-Aufruf (Android-IDs deterministisch). Fix: `ConflictAlgorithm.ignore`
  - `help_screen.dart`: „nichts wird separat gespeichert" war nach Pooling-Feature falsch → korrigiert
  - `help_screen.dart`: Projektzuordnung-Sektion beschrieb alten Single-Dropdown → auf Multi-Split aktualisiert
  - `export_service.dart`: unbenutzter `surcharge_service`-Import entfernt (Lint-Warnung)
  - `export_service.dart`: `_writeTitleRow` füllte nur Spalten 0–9 mit Titelfarbe; Zuschläge-Sheet hat 12 Spalten → auf 0–11 erweitert
  - `geofencing_background.dart`: `breakMinutes` außerhalb innerem `try`-Block deklariert (war out-of-scope nach `finally`)
  - `export_service.dart`: `fontColorHex` akzeptiert kein `ExcelColor?` → `CellStyle` im `argRow`-Closure aufgeteilt

### v1.21 – Deletion-Sync + Geofencing-Stabilität + Zuschlagsregeln

- [x] **Deletion-Sync via NAS (DB v13):**
  - Neue Tabelle `deletion_log (id, deleted_at)` auf Client und NAS
  - Jede Löschung (manuell oder per Datenpflege) schreibt einen Eintrag in `deletion_log`
  - Sync-Payload enthält `deleted_ids` (Löschungen seit letztem Sync) → NAS löscht + logt
  - Server-Response enthält `deleted_ids` anderer Geräte → Client löscht lokal per `applyRemoteDeletions()`
  - Neues NAS-Endpoint `/api/sync.ts` ersetzt das veraltete `/api/entries/sync` (vollständig: Einträge, Arbeitgeber, Standorte, Projekte, Settings, Deletion-Log)
  - `backend/lib/db.ts` erweitert: Tabellen `employers`, `tracked_locations`, `projects`, `deletion_log`, `sync_state`

- [x] **Datenpflege – Mehrfacheinträge (Einstellungen → Datenpflege):**
  - `findDuplicates()`: gruppiert Einträge nach Tag + Arbeitgeber + Startzeit-Differenz ≤ 5 Min.
  - `_DedupCard` + `_DedupDialog`: zeigt Gruppen mit Behalten (grün) / Löschen (rot durchgestrichen)
  - `deleteDuplicates()` ruft `logDeletions()` auf → Löschungen propagieren via NAS auf alle Geräte

- [x] **Geofencing-Stabilität (Oszillation):**
  - Exit-Bestätigung: 4 aufeinanderfolgende „außerhalb"-Messungen nötig (≈ 80 s Mindestzeit)
  - Hysterese-Band: Exit erst wenn Distanz > Radius + 80 m (verhindert Grenzpendeln)
  - Accuracy-Filter: GPS-Fixes schlechter als 80 m Genauigkeit werden ignoriert (Cell-Tower-Jitter)
  - Ergebnis: kein permanentes Auto-Ein/Aus-Stempeln mehr bei Cell-Tower-Wechsel

- [x] **Bugfix: Auto-Einstempeln day_type** – Geofencing-Auto-Clock-in klassifizierte immer als Werktag; jetzt korrekte Erkennung von Samstag, Sonntag, Feiertag per `HolidayService`

- [x] **Bugfix: Fahrtenbuch-Toggle** – Background-Service sah SharedPreferences-Updates aus dem Haupt-Isolate nicht (Dart-Isolate-Cache); Fix: `service.invoke('setTripTracking')` Nachrichtenkanal + lokale `_tripTrackingEnabled`-Variable im Hintergrunds-Isolate

- [x] **Zuschlagsberechnung Samstag (zeitbezogen):**
  - Vor 13:00 Uhr: kein Zuschlag (×1.0)
  - Ab 13:00 Uhr: ×1.5
  - Eintrag der beide Seiten umfasst: proportionale Berechnung (anteilig vor/nach 13:00)
  - Anzeige im Eintrag-Formular zeigt passenden Hinweistext

- [x] **AG-Wechsel auf Einträge-Screen** – `PopupMenuButton` mit `Icons.swap_horiz` in AppBar (identisch mit Berichte-Screen)

- [x] **Export-Erweiterungen:**
  - Monatsbericht-Header mit Stundensumme, Soll, Saldo
  - „Zeitraum exportieren": Von-/Bis-Monat wählen, alle Einträge in einer XLSX-Datei
  - „Jahresbericht exportieren" im Wirtschaftsjahr-Tab

- [x] **E-Mail-Analyse-Tool (`tools/mail_analyse.py`):**
  - Parst Thunderbird MBOX-Dateien, filtert nach Gurktaler-Whitelist
  - 2 Min/Mail, Eintrag am letzten Werktag des Monats
  - Ausgabe: CSV + SQL-INSERT + Protokoll-TXT; interaktiver SQLite-Import

- [x] **Bugfixes v1.21:**
  - `geofencing_background.dart`: `db.close()` nicht in allen Pfaden garantiert → `try/finally` in allen 5 DB-Funktionen nachgezogen
  - `settings_screen.dart`: `employer.nasUrl!` Null-Check fehlte → Guard + Hinweis-SnackBar
  - `backend/lib/db.ts`: `is_special_hours` fehlte in NAS time_entries-Schema → ergänzt
  - `backend/pages/api/sync.ts`: `is_special_hours` fehlte in INSERT/UPDATE → ergänzt; top-level try/catch für saubere 500-Antworten

### v1.20 – TerminMeister-Kopplung (Monatsbericht)
- [x] **`TerminMeisterService`** (`services/terminmeister_service.dart`):
  - HTTP-Client: `GET {tmUrl}/api/appointments?month=YYYY-MM`
  - Filtert serverseitig auf `status == 'abgeschlossen'`
  - Parst `TmAppointment` (id, title, type, status, startDate, participantCount, group)
  - Timeout 8 s, returns `[]` bei jedem Netzwerk-/Parsing-Fehler (TM ist optional, keine Pflicht)
- [x] **`SyncProvider` erweitert:**
  - Neue Felder `_tmUrl`, `_tmApiKey` (SharedPreferences: `tm_url`, `tm_api_key`)
  - Getters `tmUrl`, `tmApiKey`, `hasTmConfig`
  - Neue Methode `saveTmConfig(url, apiKey)`
- [x] **Einstellungen – neuer Abschnitt „TerminMeister-Kopplung":**
  - `_TmCard`-Widget (nach NAS-Verbindung) mit URL + API-Key-Dialog
  - Zeigt konfigurierte URL oder „Nicht konfiguriert"
- [x] **Monatsbericht – `_TmFuehrungenCard`:**
  - `StatefulWidget` lädt TM-Daten automatisch bei Monatswechsel (`didUpdateWidget`)
  - Gruppiert abgeschlossene Führungen nach Datum, zeigt Titel · Gruppe · Teilnehmerzahl
  - Fußzeile: „N Führungen · X Teilnehmer gesamt"
  - Karte unsichtbar wenn TM nicht konfiguriert oder keine Daten für den Monat
- [x] **NAS-Endpunkt in TM `server.js` (manuell deployen):**
  - `GET /api/appointments?month=YYYY-MM` filtert `appointments.json` nach Monat
  - Snippet liegt vor; muss in TM's `server.js` nach `/api/completed-today` eingefügt werden

### v1.19 – Urlaubstage, Krankenstand & Jahressaldo
- [x] **`vacation_days_per_year` pro Arbeitgeber (DB v12):**
  - Neues Feld auf `Employer`-Modell (int, Default 25) – `toMap`, `fromMap`, `copyWith`, `toJson` vollständig
  - DB-Migration v12: `ALTER TABLE employers ADD COLUMN vacation_days_per_year INTEGER NOT NULL DEFAULT 25`
  - NAS-Backend `server.js`: Schema + `upsertEmployer`-Statement + idempotente Migration für bestehende Server-DBs
- [x] **Einstellungen – Arbeitgeber-Dialog:**
  - Neues Textfeld „Urlaubstage/Jahr" (Standard 25) – kann pro AG unterschiedlich gesetzt werden (z.B. 26 für Gurktaler per Dienstvertrag)
- [x] **Wirtschaftsjahr-Bericht:**
  - Urlaubszeile ist **immer sichtbar** (war bisher nur bei `_vacationDays > 0`)
  - Zeigt `verbraucht / Kontingent Tage` mit Fortschrittsbalken (`.clamp(0.0, 1.0)`)
  - Zusätzlich: „Resturlaub: X Tage" (oder „Überzogen: X Tage" in Rot)
  - Kontingent kommt aus `employer.vacationDaysPerYear` statt hartkodierter `25`
- [x] **Krankenstand-Auto-Duplikation:**
  - Beim Speichern eines `WorkType.sick`-Eintrags wird für jeden weiteren Arbeitgeber automatisch eine identische Eintragung angelegt
  - Info-Text im Formular: „Krankenstand – wird automatisch für alle Arbeitgeber eingetragen."
- [x] **Handbuch:** neue Sektion „Urlaub, Krankenstand & Zeitausgleich"
- [x] **Bugfixes v1.19:**
  - `server.js` fehlte `vacation_days_per_year` in Schema + Upsert → Wert wurde bei jedem NAS-Sync verworfen (auf Default 25 zurückgesetzt)
  - `entry_form_screen.dart`: fehlender `mounted`-Check nach `await addEntry()` vor `context.read<EmployerProvider>()` → potenzieller Zugriff auf deaktivierten Context
  - **Geofencing Trip-End-Time (MIUI):** HyperOS suspendiert das Background-Isolate wenn das Gerät steht; der 2-Min-Stop-Timer feuert Stunden zu spät, `DateTime.now()` liefert dann eine falsch späte Endzeit
    - Fix: `_lastMovementTime` speichert den letzten GPS-Tick mit Geschwindigkeit ≥5 km/h
    - `_finalizeTrip` akzeptiert neuen optionalen Parameter `DateTime? endTime`
    - Stop-Timer: wenn `DateTime.now() - lastMovement > 15 Min` → `endTime = lastMovement + 2 Min`
    - Ergebnis: Fahrtenende stimmt auf ±2 Minuten auch nach MIUI-Suspension

### v1.18 – Bugfixes: Activity-Timeline + Geofencing + UX
- [x] **Adopted-State in Activity-Timeline (Issue #1):**
  - `ActivityProvider` verwaltet `_adoptedCallIds` und `_adoptedSessionIds` (Sets, in SharedPreferences persistent)
  - Neue Methoden `markCallAdopted(id)` / `markSessionAdopted(id)`
  - Nach „Übernehmen" werden Anruf/Session-Karten sofort gedimmt (Opacity 0.45), Titel durchgestrichen, Häkchen-Icon statt Button
  - Zustand bleibt auch nach App-Neustart und Datumswechsel erhalten
- [x] **Kontaktnamen für ältere Anrufe (Issue #2):**
  - `UsageStatsPlugin.kt`: neues `lookupContactName(number)` via `ContactsContract.PhoneLookup` als Fallback wenn `CACHED_NAME` leer
  - `READ_CONTACTS`-Berechtigung in AndroidManifest ergänzt
  - Anrufe aus beliebig fernen Monaten zeigen nun den Kontaktnamen wenn dieser heute im Adressbuch ist
- [x] **Auto Clock-in `travel_minutes`-Crash behoben (Issue #3):**
  - `_autoClockIn` übergab `'travel_minutes': null` an SQLite – Spalte ist `NOT NULL DEFAULT 0`
  - Fix: Key aus INSERT entfernt → Default greift automatisch
- [x] **Wochenstunden aktualisieren sich bei Arbeitgeberwechsel (Issue #6):**
  - `_EmployerChipBar.onSelected` ruft jetzt `TimeEntryProvider.setActiveEmployer(e.id)` auf
  - Wochenbalken und Stundensaldo werden sofort neu berechnet – kein Tab-Wechsel mehr nötig
- [x] **Activity-Timeline öffnet immer den heutigen Tag (Issue #7):**
  - `_load()` in `ActivityTimelineScreen` lädt stets `DateTime.now()` statt des zuletzt angezeigten `ap.selectedDate`
- [x] **Fahrten-Distanz-Bug behoben (Issue #4 + vorherige Commits):**
  - `_haversine()` gibt Meter zurück – Filter war `d < 0.5` (halbe Meter) → nie aktiv
  - Fix: `if (d < 500) _tripDistKm += d / 1000` (500 m Sprung-Filter, korrekte Einheitenumrechnung)
  - `effectiveSpeed`-Fallback nur bei `pos.speed < 0` (GPS liefert explizit keine Geschwindigkeit) – kein Jitter bei liegendem Telefon

### v1.17 – Fahrtenbuch + Bluetooth-Trigger + Bugfixes
- [x] **Fahrtenbuch (GPS-basiert):**
  - `TripRecord`-Modell, DB-Schema v11 (`trips`-Tabelle)
  - Geschwindigkeits-Erkennung im Geofencing-Hintergrunddienst: Start ≥15 km/h, Stop nach 2 Min < 5 km/h, Min-Distanz 300 m
  - `NominatimService`: Reverse-Geocoding via OpenStreetMap → Straße, Ort
  - `TripProvider`: Laden, Löschen, Verknüpfen, lazy Adressauflösung
  - `TripLogScreen`: Fahrtenliste mit Adressen, Zeit, Distanz, „Übernehmen"-Button (öffnet Eintragsformular vorausgefüllt)
  - Toggle in Einstellungen → Automatische Erfassung (Android only)
- [x] **Bluetooth-Fahrtauslöser:**
  - `BluetoothTripReceiver.kt`: BroadcastReceiver für `ACL_CONNECTED`/`ACL_DISCONNECTED`
  - Schreibt Event in SharedPreferences → Hintergrunddienst liest beim nächsten GPS-Tick
  - `BluetoothTripScreen`: Mehrfachauswahl aus gekoppelten BT-Geräten (MethodChannel → `bondedDevices`)
  - BT-Verbindung startet Fahrt sofort (ohne Geschwindigkeitsschwelle), BT-Trennung beendet sie
  - Parallelbetrieb mit Geschwindigkeitserkennung als Fallback
- [x] **Bugfixes v1.17:**
  - `updated_at` im Geofencing-Auto-Clock-in entfernt (Spalte existiert nicht in `time_entries`) → Auto-Einstempeln funktioniert wieder
  - `static const` in Dart-Funktionskörper → top-level Konstanten verschoben (Compiler-Error)
  - Kettenzuweisung `_tripId = _tripDistKm = 0` → Typfehler behoben
  - BT-Event wird jetzt erst konsumiert wenn Trip-Tracking aktiv ist (verhindert verlorene Events)
  - Null-Safety bei BT-Disconnect vor erstem GPS-Tick: `startLat/Lng` als Fallback
  - `_btTripActive` wird in allen Finalisierungs-Pfaden zurückgesetzt
  - `TripRecord.fromMap`: `created_at`-Fallback wenn DB-Feld null
  - MethodChannel-Cast in `BluetoothTripScreen` typsicher gemacht
  - Handbuch-Tab im Geofencing-Log (Einträge-Button immer sichtbar)

### v1.16 – Anruf-Tracking + Geofencing-Diagnose + Auto-Pause
- [x] **Anruf-Tracking in Activity Timeline (Android):**
  - `READ_CALL_LOG`-Berechtigung in AndroidManifest
  - Kotlin `UsageStatsPlugin`: `hasCallLogPermission` + `queryCallLog` via `CallLog.Calls` ContentProvider
  - `ActivityLog`-Modell: neue Felder `isPhoneCall`, `phoneNumber`, `callType`; `isMissed`-Getter
  - `ActivityTrackingService`: `queryCallLog()` + `hasCallLogPermission()` Methoden
  - `ActivityProvider`: lädt Anruf-Log wenn Berechtigung vorhanden; `recheckCallLogPermission()`
  - Activity-Timeline: eigener „Anrufe"-Abschnitt mit eingehenden/ausgehenden/verpassten Anrufen; Berechtigungs-Karte wenn noch nicht gewährt; „Übernehmen" erstellt `phoneCall`-Eintrag
- [x] **Geofencing-Diagnose-Log + Log-Viewer in Einstellungen:**
  - Hintergrund-Dienst schreibt strukturiertes Diagnose-Log (SharedPreferences, max. 500 Zeilen)
  - Neuer Abschnitt in den Einstellungen mit scrollbarer Log-Ansicht und Löschen-Button
  - Erleichtert die Fehlersuche bei Geofencing-Problemen ohne ADB/Logcat
- [x] **Auto-Pause 30 Min bei ≥5h Eingestempelt (nicht Homeoffice):**
  - `TimeEntryProvider` setzt beim Clock-out automatisch `break_minutes = 30` wenn `workedSeconds ≥ 5h` und Arbeitstyp nicht Homeoffice
  - Gilt auch im Background-Isolate (`geofencing_background.dart`)
  - Manuelle Pausenüberschreibung am Clock-out-Dialog funktioniert korrekt (Bugfix: manuelle Eingabe hatte keinen Vorrang)
- [x] **Bugfix Auto Clock-in fehlte `created_at`:** Background-Insert in SQLite war unvollständig → Geofencing-Auto-Clock-in hat nie funktioniert. Fix: `created_at` wird jetzt korrekt übergeben.
- [x] **Bugfix `ensureSpecialLocations` bei leerem DB:** Frischinstall ohne Standorte löste trotzdem Gurktaler-Standort-Seed aus → Duplikate bei erstem Sync. Fix: Guard auf `hasLocations()` vor `_ensureSpecialLocations()`.
- [x] **Bugfix MIUI/Xiaomi SQLite-Crash beim App-Start:** `db.execute('PRAGMA journal_mode=WAL')` im `onOpen`-Callback ist auf HyperOS/MIUI nicht erlaubt (nur `query`/`rawQuery`). Fix: `rawQuery` statt `execute`.

### v1.15 – Projektverwaltung + Bugfixes
- [x] **Projektverwaltung (Gurktaler AG):**
  - `Project`-Modell (`id`, `name`, `employerId`, `sortOrder`, `updatedAt`, `deletedAt`) mit Soft-Delete
  - `ProjectProvider`: `add()`, `remove()`, `rename()`, `forEmployer()` + automatisches Seeding der 7 Gurktaler-Projekte beim ersten Start: **Führungen, Kräutergarten, Mazeration, Kleinserie, Produktentwicklung, Rezepturoptimierung, Administration**
  - `ensureGurktalerProjects()` ist idempotent – erkennt Gurktaler AG per `name.contains('gurktaler')`, seedet nur wenn noch keine Projekte existieren
  - **DB v10:** neue Tabelle `projects` + neue Spalte `project_id` auf `time_entries`
  - **Eintrag-Formular:** Projekt-Dropdown in den Gurktaler-Sonderoptionen (Auswahl leer = „Kein Projekt")
  - **Einstellungen:** `_ProjectsCard` – erscheint nur bei Gurktaler AG; Projekte anlegen, umbenennen, löschen
  - **Berichte:** `_ProjectBreakdownCard` – erscheint nur bei Gurktaler AG; Stunden nach Projekt aufgeschlüsselt, „Kein Projekt" als Sammelkategorie
  - **NAS:** `projects`-Tabelle + bidirektionaler Sync (LWW via `e.updated_at ?? ts`), `project_id` in `time_entries`
  - `ProjectProvider.load()` wird nach jedem erfolgreichen Sync automatisch aufgerufen (`_onSyncComplete`)
- [x] **Arbeitgeber-Toggle in Berichte:**
  - Arbeitgebername als Subtitle in der AppBar des Berichte-Screens
  - `PopupMenuButton` mit `Icons.swap_horiz` für direkten Arbeitgeberwechsel ohne Tab-Wechsel
  - Nur sichtbar wenn ≥2 Arbeitgeber vorhanden
- [x] **Farbkontrast Gurktaler-Sonderoptionen behoben:** Amber-Hintergrund → Orange-Schema mit expliziten Textfarben (`Colors.black87` / `Colors.grey.shade800`) – gut lesbar in Light + Dark Mode
- [x] **Bugfix `dart:ffi` ↔ `dart:ui` Size-Konflikt:** `import 'dart:ffi' hide Size;` in `main.dart`
- [x] **Bugfix `WorkType.email` nicht exhaustiv:** `Icons.email_outlined` in `home_screen.dart` und `entries_screen.dart` ergänzt
- [x] **Bugfix Geofencing-Duplikate (zwei Root Causes dauerhaft behoben):**
  1. `LocationProvider._ensureSpecialLocations()` prüfte nur aktive `_locations` statt alle Records inkl. soft-deleted → Standort wurde bei jedem `load()` neu angelegt. Fix: `getAllLocationsForSync()` verwenden
  2. NAS `pushLocations` / `pushEmployers` verwendete Server-Timestamp `ts` als `updated_at` → „letztes Gerät das sync't gewinnt" statt „letztes Gerät das ändert gewinnt". Soft-Deletes wurden bei nächstem Sync überschrieben. Fix: `e.updated_at ?? ts` in allen Push-Handlern (locations, employers, projects)
- [x] **Bugfix Whitelist-Reset nach Neuinstallation:** Fresh-Installs senden Settings **nicht** mehr zum NAS (Guard: `settingsChangedAt == epochTs`). Verhindert, dass Default-Werte eine benutzerdefinierte NAS-Whitelist überschreiben. Einmalig gespeicherte Whitelist propagiert korrekt auf alle Geräte.
- [x] **NAS LWW-Korrektheit vollständig:** `e.updated_at ?? ts` in `pushLocations`, `pushEmployers`, `pushProjects` – Client-Timestamps überleben den Sync-Round-Trip korrekt

### v1.15 – Sonderarbeitszeiten & Vertragsäquivalent (Gurktaler AG)
- [x] **Pfau Brennerei Klagenfurt** als Standort eingepflegt (Schleppe-Platz 1, 9020 Klagenfurt am Wörthersee, 46.6415, 14.2860, Radius 150 m, WorkType `offsite`)
  - Externer Lohnabfüller für Kleinserien – Aufwand inkl. Fahrtzeit voll der Gurktaler AG zugerechnet
  - Idempotente `LocationProvider._ensureSpecialLocations()` legt den Standort bei jedem Load an, sofern noch nicht vorhanden – Identifikation per exakter Namensgleichheit
  - `employer_id` wird beim Anlegen automatisch aus dem ersten Arbeitgeber gesetzt, dessen Name „gurktaler" enthält → Geofencing-Auto-Clock-in wechselt automatisch auf Gurktaler AG beim Betreten der Zone
- [x] **Neue Spalte `is_special_hours` (DB v9, NAS-Migration idempotent):** Markierung für Sonderarbeitszeiten (hauptsächlich Führungen) am `time_entries`-Datensatz
- [x] **`SurchargeService`:** zentrale Faktor-Berechnung für Vertragsäquivalent
  - Aktiv nur bei Arbeitgeber, dessen Name `gurktaler` enthält
  - Faktoren: Sa 1.5×, So/Feiertag 2.0×, Werktag 1.0× (kein Zuschlag, gilt als Mehrarbeit)
  - Homeoffice ist immer zuschlagsfrei (auch nachts/Sa/So/Feiertag)
  - Greift nur bei explizit gesetztem `isSpecialHours`-Flag – Standard-Einträge bleiben unverändert
- [x] **Entry-Form-Erweiterung (nur sichtbar bei Gurktaler AG):**
  - Switch „Sonderarbeitszeit (Führung u. ä.)" mit Live-Anzeige des aktuellen Zuschlagsfaktors
  - Schnellschaltfläche „+80 Min Fahrtzeit" (Standardwert konfigurierbar) → schreibt in bestehendes `travel_minutes`-Feld
  - `totalDuration` rechnet Fahrtzeit nun mit ein (vorher rein dekorativ) – bestehende Einträge mit `travel_minutes = 0` unberührt
- [x] **Wirtschaftsjahr-Bericht: neue Spalte „Äquiv."** + Total-Zeile
  - Zeigt Vertragsäquivalent (Ist × Faktor) je Monat und Jahressumme
  - Hervorgehoben wenn Äquivalent > Ist (Zuschlag wirksam)
  - Erläuterungstext direkt unter der Tabelle
  - Erscheint nur bei aktivem Gurktaler-Arbeitgeber – andere Arbeitgeber sehen unverändertes Layout
- [x] **Konzeptioneller Hintergrund:** Ziel ist nicht Lohnberechnung, sondern transparente Dokumentation des tatsächlichen zeitlichen Aufwands für Vertragsverhandlungen – Vertragsäquivalent macht den faktischen Wert sichtbar, ohne die Ist-Stunden zu verfälschen

### v1.14 – Auto Clock-in via Geofencing + UX-Polishing
- [x] **Auto Clock-in/out via Geofencing** im Background-Isolate (funktioniert auch bei vollständig geschlossener App):
  - Zone betreten → SQLite-Insert eines `time_entries`-Datensatzes mit `WorkType` der Zone, `employer_id` der Zone, Notiz `Auto · [Standortname]`
  - Zone verlassen → 5-Min-Karenzzeit-Timer (GPS-Drift-Toleranz) → dann `end_time` setzen
  - Re-Entry binnen Karenzzeit → Timer wird gecancelt, kein Clock-out
  - Übersprung-Logik: kein Auto-Clock-in wenn bereits ein aktiver Eintrag existiert (egal ob manuell oder per Geofence) – Notification „Bereits eingestempelt – Geofencing übersprungen"
  - Auto-Clock-out **nur** für auto-erstellte Einträge (`geofence_auto_entry_id` in SharedPreferences) – manuelle Einträge werden nie angefasst
- [x] **Watchdog-Notification** (Periodischer Check alle 15 Min im Background-Isolate):
  - Wenn auto-erstellter Eintrag offen UND Nutzer ≥30 Min außerhalb aller Zonen → „Noch eingestempelt? Seit Xh Ym aktiv, aber außerhalb aller Zonen"
  - Notification-ID 994 wird ersetzt (kein Spam, ein einziger aktueller Reminder)
  - Manuelle Einträge werden bewusst nicht überwacht (legitimes Homeoffice ohne Fehlalarm)
- [x] **Dashboard-Notiz-Button bei aktivem Eintrag:**
  - Eintrag-Notiz wird kursiv unter dem Timer angezeigt
  - „Notiz" / „Notiz bearbeiten"-Button öffnet 3-Zeilen-Dialog mit Hint-Beispielen
  - Direktes Tätigkeits-Tagging ohne Wechsel in den Einträge-Tab
- [x] **WorkType in Background-Isolate verfügbar gemacht:** `_sendLocations()` schickt jetzt auch `workType` an das Background-Isolate, damit Auto-Clock-in den richtigen Arbeitstyp setzt
- [x] **Location-Duplikate-Fix:**
  - Seed-Guard nutzte `employer.nasUrl` (existiert seit v1.8 nicht mehr) → komplett wirkungslos, jeder Frischinstall seedete erneut → bei Sync wurden Standorte als Dubletten zur NAS gepusht
  - Neue Logik: Check über SharedPreferences `global_nas_url` + zusätzliches `locations_seeded`-Flag (nur einmal überhaupt seeden)
  - **`DatabaseHelper.deduplicateLocations()`:** Gruppiert nach Name+Koordinaten (±100 m), behält den Eintrag mit jüngstem `updated_at`, soft-deletet die Duplikate → propagiert via Sync auf alle Geräte
  - Wird bei jedem `LocationProvider.load()` ausgeführt (idempotent, billig)
- [x] **Dashboard-Wochenberechnung:**
  - **Bug behoben:** `monday`-DateTime hatte die aktuelle Uhrzeit (z.B. 09:19) → alle Montags-Einträge mit `date = 2026-05-04 00:00:00` lagen technisch „vor" diesem `monday`-Wert und wurden aus der Wochensumme gefiltert. Fix: beide Seiten der Vergleiche werden auf Mitternacht normalisiert
  - **Soll-Anzeige:** zeigt jetzt das volle Wochenziel (z.B. 8h) statt tagesanteilig (`weeklyHours/5 × Werktag`); Balken bleibt über die Woche stabil

### v1.13 – Sync-Vereinheitlichung & robuster Windows-Tray
- [x] **Ein einziger Sync-Befehl:** Reports-Tab-Sync entfernt – einzige Sync-Schaltfläche in den Einstellungen synchronisiert nun *alles* (Arbeitgeber, Standorte, Einträge, Whitelist + Activity-Settings)
- [x] **Provider-Refresh nach Sync:** `SyncProvider.setOnSyncComplete()` ruft nach jedem erfolgreichen Sync `EmployerProvider.reload()` + `LocationProvider.load()` + `TimeEntryProvider.refresh()` – neue Daten erscheinen sofort, kein App-Neustart mehr nötig
- [x] **Settings-LWW korrekt implementiert:** `ActivityProvider._settingsChangedAt` wird nur bei expliziter User-Änderung (`saveSettings()`) auf `now` gesetzt; `applyServerSettings()` schreibt direkt in Prefs, ohne den Timestamp anzufassen → das Gerät, das die Whitelist *zuletzt geändert* hat, gewinnt (nicht das, das *zuletzt synchronisiert* hat)
- [x] **Backup-Restore setzt `last_sync_at` zurück:** Auf Epoch (`1970-01-01`), damit der nächste Sync alle NAS-Daten erneut zieht – verhindert Datenverlust durch das `since`-Filter wenn Einträge zwischen Backup-Erstellung und Restore synct wurden
- [x] **Windows X-Button minimiert jetzt zuverlässig ins Tray:** `setPreventClose(true)` wurde aus `main.dart` (vor Listener-Registrierung) nach `app.dart::initState()` (direkt nach `addListener`) verschoben – ohne registrierten Listener wirkungslos
- [x] **`onWindowClose` prüft `isPreventClose()`** gemäß offiziellem `window_manager`-Pattern
- [x] **Windows-only AppBar (40 px)** auf dem HomeScreen mit zwei expliziten Icons:
  - Minimize-Icon: in Tray verstecken (gleich wie X-Button)
  - Close-Icon: echtes Beenden mit Bestätigungsdialog (Hinweis auf Tracking-Stop)
- [x] **`build.ps1` automatisiert:** holt vor jedem Build automatisch den aktuellen Branch (`git pull origin <branch>`); funktioniert vom beliebigem CWD via `$PSScriptRoot`; neue Flag `-NoPull` für Offline/Lokal-Arbeit
- [x] **Bug-Fix:** `await TrayService.instance.dispose()` (synchronous void) brach Build – await entfernt

### v1.12 – Robuste Boot-Persistenz & Tray-Stabilität
- [x] **Eigener Kotlin BootReceiver** (`ZeiterfassungBootReceiver.kt`):
  - Liest `flutter.geofencing_active` aus FlutterSharedPreferences
  - Legt Notification-Channels (`geofence_service`, `geofence_events`) idempotent an, bevor `startForegroundService()` aufgerufen wird
  - Reagiert auf `BOOT_COMPLETED` und `QUICKBOOT_POWERON` (Xiaomi/MIUI)
  - Built-in `flutter_background_service.BootReceiver` per `enabled=false` deaktiviert (Crash-Ursache)
- [x] **`autoStart: false`** in `AndroidConfiguration` – kein automatischer Service-Start ohne existierende Channels mehr
- [x] **Notification-Channels explizit im Hauptisolate** vor `FlutterBackgroundService().configure()` angelegt – Foreground-Channel mit `IMPORTANCE_LOW` (lautlos), Event-Channel mit `IMPORTANCE_DEFAULT`
- [x] **`GeofencingService.stopTracking()` async** + Persistenz des `geofencing_active`-Flags bei Start/Stop
- [x] **Windows Tray-Close-Fix:** `windowManager.setPreventClose(true)` vor `show()` – ohne diesen Aufruf ignorierte Windows den `onWindowClose()`-Handler komplett
- [x] **Race-Condition beim Beenden:** `await TrayService.dispose()` vor `windowManager.destroy()`
- [x] **Crash behoben:** `CannotPostForegroundServiceNotificationException: Bad notification for startForeground` (Android 14)

### v1.11 – NAS-Master-Sync (Soft-Delete + Settings + Backup)
- [x] **Soft-Delete für Employers + Locations:** `deleted_at`-Spalte (DB v8) statt Hard-Delete
  - `deleteEmployer()` / `deleteLocation()` setzen `deleted_at` + `updated_at`
  - `getEmployers()` / `getLocations()` filtern `WHERE deleted_at IS NULL`
  - `getAllEmployersForSync()` / `getAllLocationsForSync()` schicken auch soft-deleted Records
  - `upsertEmployersFromServer()` / `upsertLocationsFromServer()` löschen lokal wenn `deleted_at` gesetzt
  - **Löscht ein Gerät einen Arbeitgeber, wird er auf allen anderen Geräten beim nächsten Sync entfernt** – keine Duplikate mehr
- [x] **App-Settings via NAS synchronisiert:**
  - Neue Tabelle `app_settings(key, value, updated_at)` auf dem Server (LWW per Key)
  - `SyncProvider` schickt lokale Settings (Whitelist, min_duration, idle_threshold) bei jedem Sync mit
  - `ActivityProvider.applyServerSettings()` übernimmt NAS-Werte – **NAS gewinnt**
  - Whitelist-Änderung auf einem Gerät propagiert binnen Sekunden auf alle anderen
- [x] **NAS-Backup:**
  - Neue Endpunkte `POST /api/backup` und `GET /api/backup` (speichert `backup_latest.json` im DATA_DIR)
  - `BackupService.exportToNas()` / `importFromNas()`
  - Zwei neue Kacheln in den Einstellungen: „Backup auf NAS" / „Backup vom NAS"
- [x] **DB-Migration v8** ergänzt `deleted_at` auf bestehenden Installationen
- [x] **`AndroidManifest`-Merger-Konflikt** für `flutter_background_service` über `tools:replace="android:exported"` behoben
- [x] **`reports_screen` NAS-Sync** verwendet jetzt globalen `SyncProvider` statt der gelöschten per-Employer-NAS-Felder

### v1.0 – Grundgerüst
- [x] Flutter-App: Android & Windows (gemeinsame Codebasis)
- [x] Lokale SQLite-Datenbank (`sqflite`)
- [x] Zeiteinträge: Stempeluhr (Ein/Aus), manuelle Erfassung, Bearbeitung, Löschen
- [x] Arbeitstypen: Homeoffice, Telefonat, Außer-Haus-Termin, Fahrt, Büro, Sonstiges
- [x] Tagtypen: Werktag, Samstag, Sonntag, Feiertag (österr. Feiertage vorberechnet)
- [x] GPS-Erfassung (Start/End-Koordinaten, km-Distanz)
- [x] XLSX-Export (Monatsbericht mit KW-Summen, Monatsumme, Formatierung)
- [x] Mehrere Arbeitgeber, Wochenstunden-Konfiguration
- [x] NAS-Sync via Tailscale + REST-API (Upsert, bidirektional)
- [x] API-Key-Authentifizierung (optional)
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

### v1.5 – NAS-Backend & Bidirektionaler Sync
- [x] **Backend-Rewrite:** Next.js → standalone Node.js (`server.js`, kein Build-Schritt nötig)
- [x] Endpoint `POST /api/sync`: alle Tabellen bidirektional (employers, entries, locations, imap)
- [x] Last-write-wins via `updated_at`-Vergleich in SQLite UPSERT
- [x] `sync_state`-Tabelle für delta-Sync (`last_sync_at`)
- [x] DB-Migration v6: `updated_at` (employers, tracked_locations), `employer_id` (locations), `sync_state`
- [x] **Synology-Deployment:** `start_synology.sh` für Task Scheduler, `backup_synology.sh`
- [x] Automatisches tägliches Backup (30 Tage Aufbewahrung)
- [x] Android-Build vollständig eingerichtet (AGP 8.6.0, Kotlin 2.1.0, Java 17, minSdk 26)
- [x] Adaptive Launcher-Icons (mipmap-anydpi-v26)
- [x] Core library desugaring für flutter_local_notifications

### v1.10 – Windows-Platform & Build-Automatisierung
- [x] **Windows Tray-Widget vollständig implementiert** (`tray_service.dart` mit `tray_manager` + `window_manager`)
  - Tray-Menü: Öffnen / Einstempeln oder Ausstempeln / Beenden
  - Tooltip zeigt Echtzeit-Status: `Zeiterfassung · Seit 09:15 · Homeoffice`
  - X-Button minimiert ins Tray statt Beenden (`onWindowClose → windowManager.hide()`)
  - Doppelklick auf Tray-Icon öffnet Fenster wieder
  - `WindowListener`-Mixin in `app.dart`, `_syncTrayStatus()` als `TimeEntryProvider`-Listener
  - `WindowOptions`: 420×780 px, Minimum 360×600 px
- [x] **Tray-Icon Platzhalter** (`assets/tray_icon.ico`, 16×16, App-Blau #1565C0)
- [x] **`build.ps1`** im Projektroot: APK + Windows-ZIP in `builds\` mit Datums-Suffix
  - Parameter: `-Clean`, `-ApkOnly`, `-WindowsOnly`
  - Windows-EXE als ZIP (enthält EXE + DLLs aus Release-Ordner)
  - Hinweis wenn Windows-Platform noch nicht eingerichtet
- [x] **`.gitignore`** für `builds/`-Ordner (Binaries nicht im Repo)
- [ ] *Voraussetzung noch offen:* `cd app && flutter create --platforms=windows .` auf Build-Rechner ausführen

### v1.9 – Event-Fusion-Engine
- [x] **FusionEngine** (`services/fusion_engine.dart`): Clustering von ActivityLog-Sessions mit max. 10-Min-Lücke
- [x] **Coverage-Check:** Perioden die >50 % durch bestehende Einträge abgedeckt sind werden übersprungen
- [x] **Confidence-Scoring:** Basis 0.3 + Telefonat-Signale (+0.35/+0.1) + Dauer (+0.1/+0.1) + Session-Anzahl (+0.05)
- [x] **WorkType-Ableitung:** phoneCall wenn Mehrheit der Clusterzeit Anrufe, sonst offsite/homeoffice
- [x] **Deterministische Suggestion-IDs** (start+end): persistentes Verwerfen bleibt über App-Neustarts erhalten
- [x] **SuggestionProvider** (`providers/suggestion_provider.dart`): State-Management, dismissed-IDs in SharedPreferences (max. 500)
- [x] **Vorschlagskarten in ActivityTimelineScreen:** farbige Karten mit Uhrzeit, Dauer, Confidence-% (Ampelfarbe), Typ-Chip, Signal-Chips
- [x] **„Bearbeiten & Übernehmen":** öffnet `EntryFormScreen` vollständig editierbar – nichts wird automatisch gespeichert
- [x] **„Verwerfen":** persistiert dismiss, Vorschlag verschwindet dauerhaft für dieses Zeitfenster
- [x] **EntryFormScreen `forceNew`-Flag:** vorausgefüllte Einträge aus Vorschlägen/Rohdaten werden als Neu-Einträge gespeichert
- [x] Vorschläge werden nach Datumswechsel und nach Speichern eines Eintrags automatisch neu generiert

### v1.8 – Sync-Automatisierung & Geofencing-Robustheit
- [x] **Auto-Sync beim Start:** `await syncNow()` vor Provider-Reload – NAS hat Vorrang bei Erstinstallation
- [x] **Periodischer Sync:** Timer (15/30/60 Min., abschaltbar) in `SyncProvider.startPeriodicSync()`
- [x] **Trigger-basierter Sync:** 3-Sek.-Debounce nach jedem Schreibvorgang (`setSyncTrigger` in `TimeEntryProvider`)
- [x] **NAS-Konfiguration global:** `SharedPreferences` statt Arbeitgeber-Feld – konfigurierbar vor Arbeitgeber-Anlage
- [x] **NAS-Karte in Einstellungen ganz oben** (unabhängig von Arbeitgebern): URL, API-Key, Verbindungstest, Sync-Status
- [x] **Android Foreground-Service für Geofencing:** `flutter_background_service` – überlebt App-Close und Neustart, `autoStart: true`, `foregroundServiceType: location`
- [x] **Geofencing NAS-Sync-Schutz:** Default-Standorte werden nicht angelegt wenn NAS konfiguriert (verhindert Duplikate)
- [x] **Manuell-Eintrag-Button auf Dashboard:** Sichtbarer „Manuell"-Button neben Telefonat, öffnet `EntryFormScreen`

### v1.7 – UX-Verbesserungen & Backup
- [x] **Telefonat-Schnellerfassung:** Button auf Dashboard, Dialog mit Dauer (+/−5 Min.), Arbeitgeber-Auswahl, Notiz; Start = jetzt−Dauer
- [x] **Arbeitgeber-Switcher auf Dashboard:** ChoiceChip-Leiste (ab 2 Arbeitgebern), sofortiger Wechsel per Tap
- [x] **Arbeitgeber löschen:** PopupMenuButton auf jeder Arbeitgeber-Karte (Einstellungen), Bestätigungsdialog, Schutz vor Löschen des letzten Arbeitgebers
- [x] **Backup & Restore (Windows):** JSON-Export aller Tabellen + SharedPreferences via Datei-Dialog; Restore mit Bestätigungsdialog + Transaktion
- [x] **Arbeitgeber-Auswahl pro Eintrag:** Dropdown im Eintrag-Formular und Timeline-Übernehmen-Dialog
- [x] **Geofencing-Richtung:** Standort betreten → Arbeitgeber wechselt automatisch (war umgekehrt)

### v1.6 – Aktivitäts-Tracking
- [x] **ActivityLog-Modell** + DB-Migration v7 (`activity_log`-Tabelle, Windows-seitig)
- [x] **ActivityTrackingService:**
  - Windows: Win32 FFI (`GetForegroundWindow`, `GetWindowTextW`, `GetLastInputInfo`) – Poll alle 30s
  - Android: `UsageStatsManager` via MethodChannel (historische Daten, kein Hintergrunddienst)
- [x] **ActivityProvider:** start/stop Tracking, Sessions laden, Einstellungen via SharedPreferences
- [x] **ActivityTimelineScreen:** Datumspicker, Sitzungsliste mit Checkboxen, Übernehmen-Dialog
- [x] Whitelist-basierte Filterung (Browser, Office, PDF, E-Mail, Kommunikation)
- [x] Mindestdauer konfigurierbar (Standard 3 Min., 1–60 Min.)
- [x] Leerlauf-Schwelle Windows konfigurierbar (Standard 5 Min., 1–30 Min.)
- [x] **Android Quick-Settings-Tile** (`ActivityTrackingTileService.kt`) öffnet Timeline direkt
- [x] `PACKAGE_USAGE_STATS`-Berechtigung mit In-App-Erklärung und Settings-Deep-Link
- [x] Whitelist-Editor in Einstellungen (ein Eintrag pro Zeile, Reset auf Standard)
- [x] App-Icon-Mapping in Timeline (Browser, Office, PDF, Mail, Kommunikation)
- [x] Karte „Aktivitäts-Timeline" auf Dashboard (mit Tracking-Status-Indikator)
- [x] Handbuch aktualisiert (NAS-Backend Node.js, Windows-Build, Aktivitäts-Tracking)
- [x] `ffi: ^2.1.3` in pubspec.yaml

---

## Offen / In Arbeit

### Kurzfristig – Zeitausgleich-Modell

- [x] **Urlaubstage-Verwaltung (pro Arbeitgeber):** *(implementiert in v1.19)*
- [x] **Krankenstand-Auto-Duplikation:** *(implementiert in v1.19)*

- [ ] **Zeitausgleich-Modell (ZA) – Konzept noch offen:**
  - `WorkType.compensatoryLeave` existiert bereits
  - Fehlt: ZA-Konto = aufgelaufene Überstunden (Ist − Soll, kumuliert) → ZA-Anspruch in Stunden/Tagen
  - Konsumation als `compensatoryLeave`-Eintrag bucht gegen das ZA-Konto
  - Saldo-Anzeige analog Resturlaub im Jahresbericht
  - Pro AG separat (Überstunden bei AG A begründen kein ZA bei AG B)
  - *Design-Fragen offen:* Übertrag ins Folgejahr? Verfall? Auszahlung?

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
- [x] Windows-Platform aktiviert, Tray-Widget verifiziert (X-Knopf minimiert ins Tray, Beenden nur über Tray-Menü oder explizitem Close-Icon in der AppBar)
- [x] NAS-Verbindungstest auf Windows + Android erfolgreich – bidirektionaler Sync verifiziert
- [x] **Multi-Gerät-Test Soft-Delete:** APK löscht 5 Dubletten → Windows-Sync zieht 2 verbleibende Arbeitgeber – verifiziert
- [x] **Whitelist-Sync mit korrektem LWW verifiziert:** Whitelist auf Gerät ändern → anderes Gerät syncen → Änderungen erscheinen korrekt. Fresh-Installs überschreiben keine bestehenden NAS-Whitelist-Werte mehr (epochTs-Guard)
- [ ] **Backup-Restore-Test:** Backup auf NAS → neue Einträge anlegen → altes Backup wiederherstellen → Sync → fehlende Einträge müssen vom NAS zurückkommen
- [x] **Boot-Persistenz auf Xiaomi verifizieren:** Geofencing aktivieren → Telefon neu starten → Service muss ohne App-Öffnen wieder laufen – **verifiziert 2026-05-19** (Xiaomi Poco X7 Pro, HyperOS 3)
- [x] **Auto Clock-in/out auf Xiaomi verifiziert:** Gurk (500 m Zone) → Clock-in beim Betreten, Clock-out nach 5 Min Karenz beim Verlassen – **verifiziert 2026-05-20** (Xiaomi Poco X7 Pro, HyperOS 3). 5-Min-Puffer akzeptiert (geht zu Gunsten Arbeitnehmer; bei aktivem Fahrtmodus ohnehin präziser via BT/Geschwindigkeitstrigger)
- [ ] **Watchdog-Notification testen:** Auto-Eintrag offen lassen, >30 Min außerhalb aller Zonen bleiben → Reminder muss erscheinen
- [x] **Geofencing-Duplikate dauerhaft behoben:** Beide Root Causes beseitigt (ensureSpecialLocations + NAS LWW-Timestamps). Keine Neuerstellung soft-gelöschter Standorte mehr.
- [ ] **Location-Deduplizierung auf NAS verifizieren:** Nach App-Start sollen verbleibende historische Dubletten verschwinden, der NAS-Stand muss konsistent werden

### Mittelfristig – Auswertung
- [ ] **Statistik/Auswertung optimieren:** Aufschlüsselung nach Arbeitsort, nicht nur nach Typ
- [ ] Jahresexport: alle Monate des Wirtschaftsjahres in einer XLSX-Datei

### Mittelfristig – Zuschläge-Reporting (Verhandlungsunterlage Gurktaler AG)

> **Strategisches Ziel:** Vollzeitbeschäftigung (100 %) in zwei Stufen:
> 1. Nachweis, dass die aktuell erbrachte Leistung bereits ~50 % Vollzeit entspricht
>    → Formalisierung auf 50 % als erster Schritt
> 2. Zwischenstufe ~1 Jahr bei 75 % mit allen gesetzlichen Zuschlägen
>    → danach 100 % All-in
>
> Der Hauptjob lässt keine prozentuelle Eigenreduktion zu, daher kein gestaffeltes
> Angebot möglich. Die Argumentation lautet nicht „ich will mehr", sondern
> **„ich liefere bereits mehr — lasst uns das formalisieren."**
>
> **Datenbasis-Hinweis:** Vorjahreswerte zu lückenhaft. Ordentliche Erfassung läuft
> seit Mai 2026 → Auswertung ab ~August 2026 (nach 10–12 Wochen).
>
> **Vertragliche Wochenstunden Gurktaler AG:**
> | Wirtschaftsjahr | Wochenstunden |
> |---|---|
> | WJ 24/25 | 4 h/Woche |
> | WJ 25/26 (aktuell) | 8 h/Woche |
>
> Beim XLSX-Export erscheint ein Dialog mit editierbarem Wochensoll – für
> historische WJ einfach den damaligen Wert eintragen (ändert Profil nicht).
> Sobald ein neuer Vertragswert (10 h oder 12 h) fixiert ist, wird er im Code fest verankert.

**Kern-Kennzahl:** Effektiv-Äquivalent-Stunden ÷ 38,5 h × 100 = % Vollzeit
→ Wenn dieser Wert bei 45–55 % liegt, ist das Argument für 50 % Vertrag mit
Zahlen belegt, nicht nur behauptet.

- [ ] **Vollzeitäquivalent im Zuschläge-Sheet:**
  - Effektiv-Stunden / tatsächlich erfasste Wochen (nicht pauschal 52) = h/Woche
  - h/Woche ÷ 38,5 × 100 = % Vollzeit → direkt ablesbar
  - Gegenüberstellung: vertraglich 20 % vs. geleistet ~X %

- [x] **Hochrechnung Überstundenpauschale:** *(implementiert in v1.24 – So/FT-Pauschale-Karte)*
  - Monatliche So/FT-h × Stundensatz, Gegenüberstellung €400-Grenze (§ 68 EStG, seit 1.1.2024), DN + DG getrennt

- [ ] **Fahrtenleistung an So/FT als Verhandlungsargument (informativ):**
  - **Hintergrund:** Gurk ist vereinbarter Dienstort → Privatfahrten, keine Reisekostenersatzpflicht. Rechtlich akzeptiert.
    Moralisch/argumentativ: Wer für einen 8h/Woche-Job an Sonn- und Feiertagen 78 km fährt, erbringt eine
    persönliche Zusatzleistung, die nirgends sichtbar ist — aber das Argument für Stundenerhöhung + Pauschale stärkt.
  - **Strecke:** Labegg → Gurk einfach 39 km / 40 Min → Hin+Rücktour: **78 km / 80 Min**
  - **In der Pauschale-Karte (App):** neuer Abschnitt „Fahrtenleistung an So/FT":
    - Anzahl So/FT-Fahrten (Einträge mit km > 0 an So/FT-Tagen)
    - km gesamt + Fahrzeit gesamt
    - Aufwand-Äquivalent: km × **€0,50** (amtliches Kilometergeld 2026, rein informativ)
    - Hinweis: *„Privatfahrten ohne Rechtsanspruch – dient als Verhandlungsargument"*
  - **Im XLSX Zuschläge-Sheet (Argumentation-Sektion):** selbe Zahlen explizit als „privater Mehraufwand So/FT"
  - **Geofencing-Auto-km:** km-Feld bei Geofencing-Einträgen der Zone Gurk automatisch mit 78 km vorbelegen
    (konfigurierbarer Standardwert pro Zone → Zone-Einstellungen erweitern)
  - **Voraussetzung:** km-Feld bei So/FT-Einträgen befüllt — mit Auto-km wird das automatisch
  - *Datenbasis wird ab ~August 2026 aussagekräftig (10–12 Wochen saubere Erfassung)*

- [ ] **Aufschlüsselung nach Tätigkeitstyp:**
  - Führungen / Gartenarbeit / Homeoffice als eigene Untergruppen
  - Zeigt welcher Anteil zuschlagspflichtig ist und welcher als Normalarbeit gilt

- [ ] **Szenario-Vergleich (Netto-Auswirkung DN + DG):**
  - Ist: 20 % / 8 h ohne Zuschlag
  - Szenario A: 50 % formalisiert (entspricht ~Ist-Leistung)
  - Szenario B: 75 % + gesetzliche Zuschläge (~1 Jahr Zwischenstufe)
  - Szenario C: 100 % All-in (Endziel)
  - Je Szenario: Brutto DN, Lohnnebenkosten DG, steuerfreie Anteile

- [x] **Telefonat-Tracking erweitert:** Anruf-Log-Integration (READ_CALL_LOG) – letzte Anrufe in der Activity-Timeline anzeigen und direkt als Eintrag übernehmen *(v1.17)*
- [ ] **Anruf-Overlay:** Schwebender Button über der Phone-App bei aktivem Anruf (SYSTEM_ALERT_WINDOW) – sofortige Arbeitszeiterfassung ohne App-Wechsel

### Mittelfristig – Fusion-Engine Erweiterungen
- [ ] **Standort-Scoring:** GPS-Besuchshistorie loggen → Aufenthalt in definierten Zonen erhöht Confidence
- [ ] **Kalender-Regeln:** Google Calendar / Exchange-Termine als dritten Signal-Typ einbinden (hoher Confidence-Wert bei fixen Terminen)
- [ ] **Job-Profile:** Job 1 (manuell + Geofence-Reminder) vs. Job 2 (voll event-getrieben) als Einstellung pro Arbeitgeber
- [ ] **Parallelzeiten:** explizit erlaubte überlappende Einträge, getrennte Auswertung
- [ ] **Regeleditor:** Confidence-Gewichte sichtbar und manuell einstellbar (Basis, Call, Dauer, …) – erst nach einigen Wochen Praxisbetrieb sinnvoll
- [ ] **Bayesianische Gewichtsadaption** *(nach Regeleditor)*: Accept/Dismiss verschiebt Gewichte automatisch mit konfigurierbarer Lernrate (α); vollständig transparent und rücksetzbar

### Mittelfristig – Aktivitäts-Tracking Erweiterungen
- [ ] Windows Tray-Icon-Farbe während Tracking aktiv (grün = läuft, grau = inaktiv)
- [ ] Windows: Prozessname zusätzlich zum Fenstertitel für genauere Whitelist-Prüfung
- [ ] Android: App-Icon in Timeline anzeigen (PackageManager.getApplicationIcon)
- [ ] Timeline: Blöcke manuell zusammenführen (mehrere kurze Sitzungen gleicher App)

### Langfristig / Ideen
- [ ] **Kalender-Integration:** Google Calendar / Exchange-Termine als Zeiteinträge importieren
- [ ] Offline-Indikator: Anzeige wenn keine NAS-Verbindung
- [ ] E-Mail-Zeitstempel als automatische Aktivitätshinweise im Dashboard anzeigen
- [ ] IFTTT/Zapier-Webhook als alternativer Auslöser
- [ ] Mehrsprachigkeit (DE/EN)
- [x] **TerminMeister-Kopplung Szenario A:** Führungen im Monatsbericht *(implementiert v1.20)*
- [ ] **TerminMeister-Kopplung Szenario B:** NAS `shared/planned_entries.json` – keine Doppelerfassung, TM schreibt Vorschläge direkt in Zeiterfassung
- [ ] **TerminMeister-Kopplung Szenario C:** Flutter-Port – TerminMeister als Modul in Zeiterfassung

---

## Architektur-Notizen

```
app/
  lib/
    models/          time_entry, employer, tracked_location, imap_config,
                     work_type, activity_log, suggested_entry, project
    providers/       time_entry_provider, employer_provider, location_provider,
                     activity_provider (+ adopted-State für Anrufe/Sessions),
                     sync_provider, suggestion_provider, project_provider
    services/        sync_service (inkl. NAS-Backup-Endpoints),
                     export_service, import_service, gps_service,
                     holiday_service, geofencing_service (mit Boot-Flag),
                     geofencing_background (autoStart:false, Channels im Hauptisolate;
                       schreibt Auto-Clock-in/out direkt in SQLite,
                       Watchdog-Notification alle 15 Min für vergessene Clock-outs;
                       _lastMovementTime für MIUI-korrektes Trip-Ende),
                     imap_service, tray_service (tray_manager + window_manager),
                     backup_service (lokal + NAS), activity_tracking_service,
                     activity_tracking_win32, fusion_engine,
                     terminmeister_service (TmAppointment, fetchMonth – optional)
    screens/         home, entries, entry_form, reports, settings,
                     locations, imap, help, activity_timeline
    database/        database_helper (SQLite v18)
  assets/
    tray_icon.ico    16×16 Platzhalter-Icon (App-Blau #1565C0)
  android/
    kotlin/          MainActivity, UsageStatsPlugin (+ live ContactsContract-Fallback),
                     BluetoothTripReceiver, ActivityTrackingTileService,
                     ZeiterfassungBootReceiver (eigener Receiver,
                     legt Channels an bevor BackgroundService gestartet wird)
                     Permissions: ACCESS_BACKGROUND_LOCATION, POST_NOTIFICATIONS,
                                  PACKAGE_USAGE_STATS, FOREGROUND_SERVICE,
                                  FOREGROUND_SERVICE_LOCATION, RECEIVE_BOOT_COMPLETED,
                                  READ_CALL_LOG, READ_CONTACTS
                     Service: flutter_background_service
                              (autoStart:false, manuell + via eigenem BootReceiver)
  windows/           Ordner aktiv – Tray verifiziert

backend/
  server.js          Standalone Node.js, kein Build-Schritt
                     Endpunkte: /api/health, /api/sync, /api/backup,
                                /api/entries (legacy)
  package.json       Abhängigkeit: better-sqlite3
  start_synology.sh  Synology Task Scheduler Startskript
  backup_synology.sh Tägliches DB-Backup (30 Tage)
  data/              zeiterfassung.db (SQLite, WAL-Modus),
                     backup_latest.json (NAS-Backup)

build.ps1              Windows PowerShell Build-Script (APK + Windows-ZIP → builds\)
builds/                Build-Ausgaben – nicht im Git (.gitignore)
import_stempeluhr.py   Einmal-Import Stempeluhr 2.1 XLSX → SQLite (Python)
fix_worktypes.py       Korrektur-Script für falsch gemappte Arbeitstypen
```

**Datenbank-Versionen:**
- v1: `employers`, `time_entries`
- v2: + `tracked_locations`, `imap_config`
- v3: + `fiscal_year_start_month` (employers), `subject_keywords` (imap_config)
- v4: + `travel_minutes` (time_entries)
- v5: + `employer_id` (time_entries)
- v6: + `updated_at` (employers, tracked_locations), `employer_id` (tracked_locations), `sync_state`
- v7: + `activity_log`
- v8: + `deleted_at` (employers, tracked_locations) – Soft-Delete-Propagation
- v9: + `is_special_hours` (time_entries) – Sonderarbeitszeit-Flag für Zuschlagsberechnung
- v10: + `projects` (Tabelle), + `project_id` (time_entries) – Projektzuordnung
- v11: + `trips` (Tabelle) – Fahrtenbuch mit GPS-Tracking und Adressauflösung
- v12: + `vacation_days_per_year` (employers) – Urlaubskontingent pro Arbeitgeber
- v13: + `deletion_log (id, deleted_at)` – Deletion-Log für geräteübergreifende Lösch-Propagation
- v14: + `entry_project_splits (id, entry_id, project_id, minutes, ...)` – Projekt-Aufschlüsselung pro Zeiteintrag
- v15: + `device_id TEXT` + `is_synced INTEGER` auf `activity_log` – Geräte-Pooling + Sync-Flag
- v16: `day_type` auf `time_entries` – retroaktive Sa/So/FT-Kennzeichnung
- v17: + `monthly_gross REAL` (employers) – Bruttogehalt für Pauschalen-Rechner
- v18: + `default_km REAL` (tracked_locations) – Standard-Fahrstrecke pro Geofencing-Zone

**Server-DB:** `employers`, `tracked_locations`, `projects`, `deletion_log`, `entry_project_splits`, `activity_log`, `sync_state` – vollständig via `/api/sync.ts`; zusätzlich `app_settings(key, value, updated_at)` für Settings-Sync (legacy `server.js`).

**Branches:**
- `main` – stabiler Stand (v1.2)
- `claude/add-call-tracking-FyBFV` – aktueller Entwicklungsstand (v1.27)

---

## Bekannte Einschränkungen

| Thema | Details |
|---|---|
| Arbeitstyp-Konzept | WorkType vermischt Arbeitsort und Tätigkeit – Redesign geplant |
| Stempeluhr-Import E-Ort | „Mobil" wurde initial als Fahrt importiert – Korrektur via `fix_worktypes.py` |
| Hintergrund-GPS Android | Erfordert „Immer erlauben" – Android 12+ zeigt separaten Dialog |
| HyperOS/MIUI Akkuoptimierung | Xiaomi/HyperOS beendet Hintergrunddienste aggressiv – App in Akkuoptimierung auf „Keine Einschränkungen" setzen, sonst kein zuverlässiger Background-Service |
| HyperOS/MIUI SQLite | `execute()` im `onOpen`-Callback nicht erlaubt → App-Crash beim Start. Behoben via `rawQuery('PRAGMA journal_mode=WAL')` (v1.17) |
| IMAP ohne SSL | Port 143 möglich, nicht empfohlen für produktive Nutzung |
| Windows Tray | Funktioniert. X-Knopf minimiert ins Tray (`setPreventClose` nach `addListener`), Beenden über Tray-Menü oder explizites Close-Icon in der AppBar mit Bestätigungsdialog |
| Settings-Sync Timing | LWW basiert auf "Gerät hat Setting zuletzt geändert" – nicht auf Sync-Reihenfolge. Erfordert konsistente Systemuhren auf allen Geräten |
| Backup-Restore | Setzt `last_sync_at` lokal auf Epoch zurück, damit beim nächsten Sync alle NAS-Daten neu gezogen werden. NAS-Stand gewinnt per LWW – Backup ist nur dann „die Wahrheit", wenn der NAS keine neueren Daten hat |
| Windows Aktivitäts-Tracking | Win32 FFI eingebaut – funktionsfähig |
| NAS-Backup | Tägliches Backup läuft nach jedem erfolgreichen Sync (SyncProvider). Monatliches/jährliches Backup via Geofencing-Foreground-Service. Fehlerursache wird im Geofencing-Log geloggt (HTTP-Status, Timeout, Exception). Restore über Einstellungen → NAS-Backups. |
| Android Aktivitäts-Tracking | UsageStatsManager: nur App-Name, kein Dokument-Titel; geringere Granularität als Windows |
| iOS | Nicht geplant – kein Geofencing im Hintergrund, kein Anruf-Tracking |
| Überstunden-Kalkulation | Bewusst nicht implementiert (keine automatischen Zuschläge). Ausnahme: Vertragsäquivalent für Gurktaler AG im Jahresbericht – informativ, beeinflusst Ist-Stunden nicht |
| Sonderarbeitszeit-Faktoren | Hardcoded für Gurktaler AG (Sa 1.5×, So/Feiertag 2.0×). Andere Arbeitgeber: Spalte ausgeblendet, kein Effekt. Erweiterbar via `SurchargeService` |
| Projektverwaltung | Projekte sind aktuell Gurktaler AG vorbehalten (Seeding + UI). Andere Arbeitgeber können Projekte anlegen, aber ohne automatisches Seeding. Projektzuordnung optional – Einträge ohne Projekt erscheinen unter „Kein Projekt" im Bericht |
| NAS-Prozess-Persistenz | Aktuell via `nohup` + `disown` gestartet (Benutzer Wolfgang). Bei NAS-Neustart muss der Server manuell oder per DSM Task Scheduler neu gestartet werden |
| Auto Clock-in/out | Funktioniert auch bei geschlossener App (Background-Isolate schreibt direkt in SQLite). 5 Min Karenz beim Verlassen einer Zone gegen GPS-Drift. Auto-Clock-out greift nur bei Einträgen, die selbst per Geofencing erstellt wurden – manuelle Einträge bleiben unangetastet |
| Geofencing-Watchdog | Schlägt nur Alarm bei auto-erstellten Einträgen, nicht bei manuellen (kein Fehlalarm für legitimes Homeoffice). Schwelle: 30 Min außerhalb aller Zonen. Notification-ID 994 wird ersetzt – kein Spam |
| GPS-Genauigkeits-Schwelle | `_kMaxAccuracyM = 150.0 m` (v1.27, davor 80 m). Beim Poco X7 Pro im Gebäude liefert das GPS-System Cell/WiFi-Fallback mit ~100 m Genauigkeit. 150 m ist ausreichend, da alle konfigurierten Zonen > 9 km entfernt liegen. |
| Backup-Retry-Cooldown | Nach fehlgeschlagenem geplanten Backup (täglich/monatlich/jährlich) wird frühestens 30 Min später erneut versucht (`backup_last_*_attempt` in SharedPreferences). Verhindert Retry-Spam bei dauerhaft fehlender NAS-Verbindung. |
