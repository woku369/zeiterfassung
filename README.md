# Zeiterfassung

Arbeitszeiterfassung für **Android** und **Windows** mit NAS-Synchronisation via Tailscale.

Inspiriert von *Stempeluhr 2.1* von Matthias Lenkeit.

---

## Projektstruktur

```
├── app/          # Flutter-App (Android + Windows)
├── backend/      # Standalone Node.js API-Server (läuft auf Synology NAS)
├── build.ps1     # PowerShell Build-Script (APK + Windows-ZIP)
├── import_stempeluhr.py  # Einmal-Import aus Stempeluhr 2.1 XLSX
└── fix_worktypes.py      # Korrektur-Script für importierte Einträge
```

---

## Features

- **Einstempeln / Ausstempeln** per Knopfdruck mit Timer
- **Manuelle Einträge** (vergangene Zeiten nachtragen)
- **Auto-Pause:** 30 Min werden automatisch eingetragen bei ≥5h Eingestempelt (außer Homeoffice)
- **Tätigkeitsarten:** Homeoffice, Telefonat, Außer-Haus-Termin, Fahrt, Büro, Sonstiges
- **Tagtypen:** Werktag, Samstag, Sonntag, Feiertag (manuell – keine automatischen Zuschläge)
- **Fahrtstrecken** in km erfassbar
- **GPS-Erfassung** auf Android (Koordinaten für Fahrtbeginn/-ende)
- **Geofencing:** automatisches Clock-in/out beim Betreten/Verlassen definierter Zonen (Background-Service)
- **Österreichische Feiertage** vorberechnet und angezeigt
- **Aktivitäts-Tracking:** Windows (Win32 FFI) + Android (UsageStatsManager) mit Fusion-Engine für Zeiterfassungsvorschläge
- **Anruf-Tracking (Android):** Anruf-Log in Activity-Timeline, direkt als Eintrag übernehmen
- **XLSX-Export** (monatlich, mit Wochen-Subtotalen)
- **XLSX-Import** aus Stempeluhr 2.1 und kompatiblen Formaten
- **NAS-Sync** via Tailscale + REST-API (bidirektional, LWW, delta-Sync)
- **Offline-fähig** (lokale SQLite-Datenbank, v10)
- **Mehrere Arbeitgeber**, Wochenstunden-Konfiguration, Wirtschaftsjahr-Bericht
- **Projektverwaltung** (Gurktaler AG: 7 Projekte mit Stunden-Aufschlüsselung)
- **Windows Tray-Widget** (X-Knopf minimiert ins Tray, Beenden nur über Menü/Icon)

---

## App einrichten (Flutter)

### Voraussetzungen
- Flutter SDK ≥ 3.22
- Android Studio oder VS Code mit Flutter-Extension
- Für Windows-Build: Visual Studio mit C++-Workload

### Installation

```bash
cd app
flutter pub get
flutter run                    # Android (Gerät angeschlossen)
flutter run -d windows         # Windows
flutter build apk --release    # Android APK
flutter build windows --release
```

### Build-Script (Windows)

```powershell
# Im Projektroot:
.\build.ps1              # APK + Windows-ZIP
.\build.ps1 -ApkOnly     # Nur APK
.\build.ps1 -WindowsOnly # Nur Windows
.\build.ps1 -NoPull      # Kein git pull vor dem Build
```

Builds landen in `builds\` (nicht im Git).

---

## Backend einrichten (Synology NAS)

Das Backend ist ein **standalone Node.js**-Server ohne Build-Schritt.

```bash
cd backend
npm install
node server.js
# oder via start_synology.sh für den DSM Task Scheduler
```

Die API läuft auf Port **3000**. Über Tailscale erreichbar unter `http://<tailscale-ip>:3000`.

### API-Endpunkte

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | `/api/health` | Verbindungstest |
| POST | `/api/sync` | Bidirektionaler Sync (Arbeitgeber, Einträge, Standorte, IMAP, Settings, Projekte) |
| POST | `/api/backup` | Backup auf NAS speichern (`backup_latest.json`) |
| GET | `/api/backup` | Backup vom NAS laden |

Authentifizierung via Header: `x-api-key: <key>` (optional, in `server.js` konfigurieren).

### Synology-Deployment

```bash
# Hintergrundstart (manuell):
nohup node server.js > server.log 2>&1 &

# Automatischer Start via DSM Task Scheduler:
bash /volume1/zeiterfassung/backend/start_synology.sh

# Tägliches DB-Backup (30 Tage Aufbewahrung):
bash /volume1/zeiterfassung/backend/backup_synology.sh
```

---

## App-Einstellungen

In der App unter **Einstellungen**:
1. **NAS-URL** eintragen: `http://<tailscale-ip>:3000` (oben, unabhängig von Arbeitgebern)
2. API-Key (falls konfiguriert)
3. Verbindung testen
4. Arbeitgeber anlegen (Name + Wochenstunden + Wirtschaftsjahresbeginn)
5. Standorte konfigurieren (Geofencing, Radius 50–1000 m)

---

## XLSX-Import aus Stempeluhr 2.1

Die App erkennt automatisch Spalten nach Bezeichnung (Datum, Beginn, Ende, Pause, Notiz).  
Unterstützte Datumsformate: `DD.MM.YYYY`, `YYYY-MM-DD`, `DD/MM/YYYY`.  
Pausenformat: Minuten (z. B. `30`) oder `HH:MM`.

Import unter **Berichte → XLSX importieren**.

Alternativ: `import_stempeluhr.py` schreibt direkt in die SQLite-Datenbank (Python).

---

## Geofencing (Android)

- Konfigurierbare Standorte (Name, GPS-Koordinaten, Radius, Arbeitstyp, Arbeitgeber)
- Auto-Clock-in beim Betreten, Auto-Clock-out (5 Min Karenz) beim Verlassen
- Funktioniert auch bei vollständig geschlossener App (Foreground-Service)
- **Wichtig (Xiaomi/HyperOS):** App in Akkuoptimierung auf „Keine Einschränkungen" setzen
- Diagnose-Log in den Einstellungen (Geofencing-Abschnitt) für Fehlersuche

---

## Aktivitäts-Tracking

- **Windows:** Win32 FFI – aktives Fenster alle 30 s erfassen, Whitelist-basierte Filterung
- **Android:** UsageStatsManager – App-Nutzungshistorie; Berechtigung „App-Nutzungsdaten" erforderlich
- **Anruf-Tracking (Android):** `READ_CALL_LOG`-Berechtigung → eingehende/ausgehende/verpasste Anrufe in Activity-Timeline
- **Fusion-Engine:** clustert Sessions (max. 10-Min-Lücke), berechnet Confidence-Score, schlägt Zeiteinträge vor
- Mindestdauer, Leerlauf-Schwelle und Whitelist konfigurierbar in den Einstellungen

---

## Feiertage (Österreich)

Alle bundesweiten Feiertage sind vorberechnet. Der **Tagtyp wird niemals automatisch gesetzt** – immer manuell beim Erstellen/Bearbeiten eines Eintrags wählen. Keine automatischen Zuschläge für Wochenenden, Feiertage oder Nachtstunden.

---

## Datenpfade

| Plattform | Datenbankpfad |
|-----------|---------------|
| Android | App-internes Verzeichnis (SQLite) |
| Windows | `%APPDATA%\zeiterfassung\zeiterfassung.db` |
| NAS | `backend/data/zeiterfassung.db` |

---

## Bekannte Einschränkungen

- **Xiaomi/HyperOS:** Hintergrunddienste werden aggressiv beendet → Akkuoptimierung auf „Keine Einschränkungen"
- **Android Aktivitäts-Tracking:** nur App-Name (kein Dokument-Titel), geringere Granularität als Windows
- **iOS:** nicht geplant
