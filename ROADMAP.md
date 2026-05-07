# Zeiterfassung – Roadmap

> Automatisch gepflegt via `/roadmap`. Manuell aktualisieren nach größeren Änderungen.
> Letztes Update: 2026-05-07 – Auto Clock-in via Geofencing + Watchdog

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

---

## Erledigt

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
- [ ] **Whitelist-Sync mit korrektem LWW verifizieren:** Whitelist auf Windows ändern → APK syncen → muss übernommen werden (auch wenn APK später erneut sync't, darf sie die Windows-Werte nicht überschreiben)
- [ ] **Backup-Restore-Test:** Backup auf NAS → neue Einträge anlegen → altes Backup wiederherstellen → Sync → fehlende Einträge müssen vom NAS zurückkommen
- [ ] **Boot-Persistenz auf Xiaomi verifizieren:** Geofencing aktivieren → Telefon neu starten → Service muss ohne App-Öffnen wieder laufen
- [ ] **Auto Clock-in/out auf Xiaomi verifizieren:** Geofencing-Zone fahren → Notification + Eintrag erscheint → Zone verlassen → 5 Min Karenz → Eintrag wird geschlossen
- [ ] **Watchdog-Notification testen:** Auto-Eintrag offen lassen, >30 Min außerhalb aller Zonen bleiben → Reminder muss erscheinen
- [ ] **Location-Deduplizierung auf NAS verifizieren:** Nach App-Start sollen Dubletten verschwinden, der NAS-Stand muss konsistent werden

### Mittelfristig – Auswertung
- [ ] **Statistik/Auswertung optimieren:** Aufschlüsselung nach Arbeitsort, nicht nur nach Typ
- [ ] Jahresexport: alle Monate des Wirtschaftsjahres in einer XLSX-Datei
- [ ] **Telefonat-Tracking erweitert:** Anruf-Log-Integration (READ_CALL_LOG) – letzte Anrufe anzeigen und direkt als Eintrag übernehmen
- [ ] **Anruf-Overlay:** Schwebender Button über der Phone-App bei aktivem Anruf (SYSTEM_ALERT_WINDOW) – sofortige Arbeitszeiterfassung ohne App-Wechsel; erst nach Praxistest des Dashboard-Buttons evaluieren

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

---

## Architektur-Notizen

```
app/
  lib/
    models/          time_entry, employer, tracked_location, imap_config,
                     work_type, activity_log, suggested_entry
    providers/       time_entry_provider, employer_provider, location_provider,
                     activity_provider, sync_provider, suggestion_provider
    services/        sync_service (inkl. NAS-Backup-Endpoints),
                     export_service, import_service, gps_service,
                     holiday_service, geofencing_service (mit Boot-Flag),
                     geofencing_background (autoStart:false, Channels im Hauptisolate;
                       schreibt Auto-Clock-in/out direkt in SQLite,
                       Watchdog-Notification alle 15 Min für vergessene Clock-outs),
                     imap_service, tray_service (tray_manager + window_manager),
                     backup_service (lokal + NAS), activity_tracking_service,
                     activity_tracking_win32, fusion_engine
    screens/         home, entries, entry_form, reports, settings,
                     locations, imap, help, activity_timeline
    database/        database_helper (SQLite v7)
  assets/
    tray_icon.ico    16×16 Platzhalter-Icon (App-Blau #1565C0)
  android/
    kotlin/          MainActivity, UsageStatsPlugin, ActivityTrackingTileService,
                     ZeiterfassungBootReceiver (eigener Receiver,
                     legt Channels an bevor BackgroundService gestartet wird)
                     Permissions: ACCESS_BACKGROUND_LOCATION, POST_NOTIFICATIONS,
                                  PACKAGE_USAGE_STATS, FOREGROUND_SERVICE,
                                  FOREGROUND_SERVICE_LOCATION, RECEIVE_BOOT_COMPLETED
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

**Server-DB:** zusätzlich `app_settings(key, value, updated_at)` für Settings-Sync.

**Branches:**
- `main` – stabiler Stand (v1.2)
- `claude/add-call-tracking-FyBFV` – aktueller Entwicklungsstand (v1.14)

---

## Bekannte Einschränkungen

| Thema | Details |
|---|---|
| Arbeitstyp-Konzept | WorkType vermischt Arbeitsort und Tätigkeit – Redesign geplant |
| Stempeluhr-Import E-Ort | „Mobil" wurde initial als Fahrt importiert – Korrektur via `fix_worktypes.py` |
| Hintergrund-GPS Android | Erfordert „Immer erlauben" – Android 12+ zeigt separaten Dialog |
| HyperOS/MIUI Akkuoptimierung | Xiaomi/HyperOS beendet Hintergrunddienste aggressiv – App in Akkuoptimierung auf „Keine Einschränkungen" setzen, sonst kein zuverlässiger Background-Service |
| IMAP ohne SSL | Port 143 möglich, nicht empfohlen für produktive Nutzung |
| Windows Tray | Funktioniert. X-Knopf minimiert ins Tray (`setPreventClose` nach `addListener`), Beenden über Tray-Menü oder explizites Close-Icon in der AppBar mit Bestätigungsdialog |
| Settings-Sync Timing | LWW basiert auf "Gerät hat Setting zuletzt geändert" – nicht auf Sync-Reihenfolge. Erfordert konsistente Systemuhren auf allen Geräten |
| Backup-Restore | Setzt `last_sync_at` lokal auf Epoch zurück, damit beim nächsten Sync alle NAS-Daten neu gezogen werden. NAS-Stand gewinnt per LWW – Backup ist nur dann „die Wahrheit", wenn der NAS keine neueren Daten hat |
| Windows Aktivitäts-Tracking | Win32 FFI eingebaut – funktionsfähig |
| NAS-Backup | Speichert immer nur das letzte Backup (`backup_latest.json`) – keine Versionierung. Tägliches DB-Backup via `backup_synology.sh` bleibt zusätzliche Sicherung |
| Android Aktivitäts-Tracking | UsageStatsManager: nur App-Name, kein Dokument-Titel; geringere Granularität als Windows |
| iOS | Nicht geplant – kein Geofencing im Hintergrund, kein Anruf-Tracking |
| Überstunden-Kalkulation | Bewusst nicht implementiert (keine automatischen Zuschläge) |
| Auto Clock-in/out | Funktioniert auch bei geschlossener App (Background-Isolate schreibt direkt in SQLite). 5 Min Karenz beim Verlassen einer Zone gegen GPS-Drift. Auto-Clock-out greift nur bei Einträgen, die selbst per Geofencing erstellt wurden – manuelle Einträge bleiben unangetastet |
| Geofencing-Watchdog | Schlägt nur Alarm bei auto-erstellten Einträgen, nicht bei manuellen (kein Fehlalarm für legitimes Homeoffice). Schwelle: 30 Min außerhalb aller Zonen. Notification-ID 994 wird ersetzt – kein Spam |
