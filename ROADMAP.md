# Zeiterfassung – Roadmap

> Automatisch gepflegt via `/roadmap`. Manuell aktualisieren nach größeren Änderungen.
> Letztes Update: 2026-05-14 – v1.19 Urlaubstage/Krankenstand implementiert

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
- [ ] **Boot-Persistenz auf Xiaomi verifizieren:** Geofencing aktivieren → Telefon neu starten → Service muss ohne App-Öffnen wieder laufen
- [ ] **Auto Clock-in/out auf Xiaomi verifizieren:** Geofencing-Zone fahren → Notification + Eintrag erscheint → Zone verlassen → 5 Min Karenz → Eintrag wird geschlossen
- [ ] **Watchdog-Notification testen:** Auto-Eintrag offen lassen, >30 Min außerhalb aller Zonen bleiben → Reminder muss erscheinen
- [x] **Geofencing-Duplikate dauerhaft behoben:** Beide Root Causes beseitigt (ensureSpecialLocations + NAS LWW-Timestamps). Keine Neuerstellung soft-gelöschter Standorte mehr.
- [ ] **Location-Deduplizierung auf NAS verifizieren:** Nach App-Start sollen verbleibende historische Dubletten verschwinden, der NAS-Stand muss konsistent werden

### Mittelfristig – Auswertung
- [ ] **Statistik/Auswertung optimieren:** Aufschlüsselung nach Arbeitsort, nicht nur nach Typ
- [ ] Jahresexport: alle Monate des Wirtschaftsjahres in einer XLSX-Datei
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
                       Watchdog-Notification alle 15 Min für vergessene Clock-outs),
                     imap_service, tray_service (tray_manager + window_manager),
                     backup_service (lokal + NAS), activity_tracking_service,
                     activity_tracking_win32, fusion_engine
    screens/         home, entries, entry_form, reports, settings,
                     locations, imap, help, activity_timeline
    database/        database_helper (SQLite v12)
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

**Server-DB:** zusätzlich `app_settings(key, value, updated_at)` für Settings-Sync; `projects` (Tabelle) für bidirektionalen Projekt-Sync.

**Branches:**
- `main` – stabiler Stand (v1.2)
- `claude/add-call-tracking-FyBFV` – aktueller Entwicklungsstand (v1.19)

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
| NAS-Backup | Speichert immer nur das letzte Backup (`backup_latest.json`) – keine Versionierung. Tägliches DB-Backup via `backup_synology.sh` bleibt zusätzliche Sicherung |
| Android Aktivitäts-Tracking | UsageStatsManager: nur App-Name, kein Dokument-Titel; geringere Granularität als Windows |
| iOS | Nicht geplant – kein Geofencing im Hintergrund, kein Anruf-Tracking |
| Überstunden-Kalkulation | Bewusst nicht implementiert (keine automatischen Zuschläge). Ausnahme: Vertragsäquivalent für Gurktaler AG im Jahresbericht – informativ, beeinflusst Ist-Stunden nicht |
| Sonderarbeitszeit-Faktoren | Hardcoded für Gurktaler AG (Sa 1.5×, So/Feiertag 2.0×). Andere Arbeitgeber: Spalte ausgeblendet, kein Effekt. Erweiterbar via `SurchargeService` |
| Projektverwaltung | Projekte sind aktuell Gurktaler AG vorbehalten (Seeding + UI). Andere Arbeitgeber können Projekte anlegen, aber ohne automatisches Seeding. Projektzuordnung optional – Einträge ohne Projekt erscheinen unter „Kein Projekt" im Bericht |
| NAS-Prozess-Persistenz | Aktuell via `nohup` + `disown` gestartet (Benutzer Wolfgang). Bei NAS-Neustart muss der Server manuell oder per DSM Task Scheduler neu gestartet werden |
| Auto Clock-in/out | Funktioniert auch bei geschlossener App (Background-Isolate schreibt direkt in SQLite). 5 Min Karenz beim Verlassen einer Zone gegen GPS-Drift. Auto-Clock-out greift nur bei Einträgen, die selbst per Geofencing erstellt wurden – manuelle Einträge bleiben unangetastet |
| Geofencing-Watchdog | Schlägt nur Alarm bei auto-erstellten Einträgen, nicht bei manuellen (kein Fehlalarm für legitimes Homeoffice). Schwelle: 30 Min außerhalb aller Zonen. Notification-ID 994 wird ersetzt – kein Spam |
