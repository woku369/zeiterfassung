# Zeiterfassung – Roadmap

> Automatisch gepflegt via `/roadmap`. Manuell aktualisieren nach größeren Änderungen.
> Letztes Update: 2026-04-30 – Hardware dokumentiert, iOS gestrichen

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
- [x] XLSX-Import (kompatibel mit Stempeluhr 2.1, Datumsformat-Autoerkennung)
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

---

## Offen / In Arbeit

### Kurzfristig
- [ ] **Windows-Platform aktivieren:** `flutter create --platforms=windows .` ausführen
- [ ] **Tray-Widget fertigstellen:** Auskommentierte Zeilen in `tray_service.dart` aktivieren, `assets/tray_icon.ico` hinzufügen
- [ ] IMAP: `subject_keywords`-Spalte in DB-Migration v3 ergänzen (für bestehende Installationen)
- [ ] Geofencing: „Immer erlauben"-Dialog für Hintergrund-GPS führen Nutzer durch

### Mittelfristig
- [ ] **Telefonat-Tracking:** Anrufdauer bekannter Nummern erfassen, optional als Eintrag vorschlagen
- [ ] **Kalender-Integration:** Google Calendar / Exchange-Termine als Zeiteinträge importieren
- [ ] **Wochenstunden-Report:** Soll/Ist-Vergleich über mehrere Wochen (Basis für Vertragsanpassung)
- [ ] Jahresexport: alle Monate in einer XLSX-Datei mit Jahresübersicht
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
    database/        database_helper (SQLite v2)
  android/           ACCESS_BACKGROUND_LOCATION, POST_NOTIFICATIONS
  windows/           (noch nicht generiert – flutter create --platforms=windows .)

backend/
  pages/api/         health, entries/index, entries/sync, entries/[id]
  lib/               db.ts (SQLite + WAL), auth.ts (API-Key)
```

**Datenbank-Versionen:**
- v1: `employers`, `time_entries`
- v2: + `tracked_locations`, `imap_config`

**Branches:**
- `main` – stabiler Stand
- `feature/geofencing-imap-tray` – aktueller Entwicklungsstand (v1.1 + v1.2)

---

## Bekannte Einschränkungen

| Thema | Details |
|---|---|
| Hintergrund-GPS Android | Erfordert „Immer erlauben" – Android 12+ zeigt separaten Dialog |
| HyperOS/MIUI Akkuoptimierung | Xiaomi/HyperOS beendet Hintergrunddienste aggressiv – App in Akkuoptimierung auf „Keine Einschränkungen" setzen, sonst kein Geofencing im Hintergrund |
| IMAP ohne SSL | Port 143 möglich, nicht empfohlen für produktive Nutzung |
| Windows Tray | Noch nicht fertig – Windows-Platform-Ordner fehlt |
| iOS | Nicht geplant – kein Geofencing im Hintergrund, kein Anruf-Tracking |
| Überstunden-Kalkulation | Bewusst nicht implementiert (keine automatischen Zuschläge) |
