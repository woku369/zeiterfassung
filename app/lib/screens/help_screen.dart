import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handbuch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            icon: Icons.rocket_launch_outlined,
            title: 'Schnellstart',
            children: [
              _Para(
                'Diese App erfasst Arbeitszeiten für Teilzeitarbeit an '
                'wechselnden Orten und Geräten. Alle Daten liegen lokal auf '
                'dem jeweiligen Gerät und werden optional mit dem NAS '
                'synchronisiert.',
              ),
              _Step(number: '1', text: 'NAS-URL eintragen: Einstellungen → NAS-Verbindung (ganz oben)'),
              _Step(number: '2', text: '"Verbinden" – Arbeitgeber und Einträge werden automatisch synchronisiert'),
              _Step(number: '3', text: 'Arbeitgeber anlegen falls noch keiner vorhanden (oder per Sync erhalten)'),
              _Step(number: '4', text: 'Standorte definieren für automatische Arbeitgeber-Erkennung'),
              _Step(number: '5', text: 'IMAP-Konto einrichten für E-Mail-Sortierung'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.vpn_lock_outlined,
            title: 'Tailscale – Gerät einrichten',
            children: [
              _Para(
                'Tailscale verbindet alle Geräte in einem privaten Netzwerk, '
                'damit die App von überall auf das NAS zugreifen kann – '
                'ohne Port-Freigaben oder VPN-Konfiguration.',
              ),
              _SubHeading('Installation'),
              _Step(number: '1', text: 'tailscale.com → Download für Android / Windows'),
              _Step(number: '2', text: 'Mit demselben Account anmelden wie auf dem NAS'),
              _Step(number: '3', text: 'Tailscale-IP des NAS notieren (z. B. 100.x.x.x)'),
              _SubHeading('Überprüfung'),
              _Code('ping 100.x.x.x'),
              _Para('Im Tailscale-Dashboard unter admin.tailscale.com '
                  'sollten alle aktiven Geräte mit grünem Punkt erscheinen.'),
              _Hint('NAS und das verwendete Gerät müssen beide im selben '
                  'Tailscale-Netzwerk sein und online sein.'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.storage_outlined,
            title: 'NAS – Backend einrichten',
            children: [
              _Para(
                'Das Backend ist ein Node.js-Server (server.js) der auf der '
                'Synology läuft. Er nimmt Sync-Anfragen entgegen und speichert '
                'Daten in einer SQLite-Datenbank.',
              ),
              _SubHeading('Synology-Setup (einmalig)'),
              _Step(number: '1', text: 'Node.js v20 über den Synology Package Manager installieren'),
              _Step(number: '2', text: 'Verzeichnis /volume1/Gurktaler/zeiterfassung/backend anlegen'),
              _Step(number: '3', text: 'Dateien server.js, package.json per SSH übertragen'),
              _Step(number: '4', text: 'npm install im backend-Verzeichnis ausführen'),
              _Step(number: '5', text: 'start_synology.sh als Aufgabe beim Systemstart eintragen'),
              _SubHeading('Aufgabenplaner (Systemstart)'),
              _Code(
                '# Systemsteuerung → Aufgabenplaner → Erstellen\n'
                '# Benutzer: admin · Typ: Beim Systemstart\n'
                'sh /volume1/Gurktaler/zeiterfassung/backend/start_synology.sh',
              ),
              _SubHeading('Verbindung testen'),
              _Code('curl -H "x-api-key: ZE-Gurktaler-2026" \\\n  http://100.121.103.107:3000/api/health'),
              _SubHeading('In der App konfigurieren'),
              _Step(number: '1', text: 'Einstellungen → NAS-Verbindung (ganz oben, vor Arbeitgebern)'),
              _Step(number: '2', text: 'URL: http://100.121.103.107:3000'),
              _Step(number: '3', text: 'API-Key: ZE-Gurktaler-2026'),
              _Step(number: '4', text: '"Verbindung testen" bestätigt die Erreichbarkeit'),
              _Hint(
                'NAS-Konfiguration ist unabhängig von Arbeitgebern – '
                'NAS zuerst einrichten, dann synchronisieren. '
                'Backup läuft automatisch täglich via Aufgabenplaner → '
                'backup_synology.sh (30 Tage Aufbewahrung).',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.devices_outlined,
            title: 'Mehrere Geräte – Workflow',
            children: [
              _Para(
                'Die App funktioniert auf jedem Gerät unabhängig. '
                'Synchronisierung läuft automatisch – beim Start, '
                'periodisch und nach jeder Datenänderung.',
              ),
              _SubHeading('Automatische Synchronisierung'),
              _KeyValue(label: 'Beim Start', value: 'NAS-Daten werden sofort geladen (NAS hat Vorrang)'),
              _KeyValue(label: 'Periodisch', value: 'Alle 15 / 30 / 60 Min. (in Einstellungen wählbar)'),
              _KeyValue(label: 'Nach Änderung', value: '3 Sek. nach jedem Speichern/Löschen'),
              _SubHeading('Empfohlener Workflow'),
              _Step(
                number: '1',
                text: 'NAS-URL einmalig einrichten – fertig. Sync läuft automatisch.',
              ),
              _Step(
                number: '2',
                text: 'Einträge auf Gerät A erfassen (auch offline möglich)',
              ),
              _Step(
                number: '3',
                text: 'Gerät B öffnen → beim Start werden alle Einträge geladen',
              ),
              _Hint(
                'NAS ist Master: Löschungen, Whitelist und App-Settings '
                'propagieren auf alle Geräte. Einträge mit gleicher ID werden '
                'per last-write-wins gemerged. Manueller Sync jederzeit: '
                'Einstellungen → Sync-Status → Jetzt.',
              ),
              _SubHeading('Geräte-Übersicht'),
              _KeyValue(label: 'Android', value: 'GPS, Geofencing (Foreground-Service), Sync, Boot-Restart'),
              _KeyValue(label: 'Windows', value: 'Tray-Widget, Aktivitäts-Tracking, IMAP, Sync'),
              _KeyValue(label: 'NAS', value: 'Master-Datenspeicher, immer online'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Geofencing – Standorte',
            children: [
              _Para(
                'Das Geofencing läuft als permanenter Android-Foreground-Service '
                'im Hintergrund – auch wenn die App geschlossen ist. '
                'Beim Betreten eines Standorts wird automatisch der zugehörige '
                'Arbeitgeber aktiviert.',
              ),
              _SubHeading('Einrichtung'),
              _Step(number: '1', text: 'Einstellungen → Automatische Erfassung → Standorte'),
              _Step(number: '2', text: '"Aktuelle Position verwenden" vor Ort antippen'),
              _Step(number: '3', text: 'Radius je nach Gelände: 100–500 m'),
              _Step(number: '4', text: 'Arbeitgeber dem Standort zuordnen'),
              _Step(number: '5', text: 'Tracking oben rechts aktivieren – läuft ab sofort permanent'),
              _SubHeading('Auto Clock-in / Clock-out'),
              _Para(
                'Sobald du eine Zone betrittst, wird automatisch '
                'eingestempelt – mit dem Arbeitgeber und dem Arbeitstyp '
                'der Zone. Beim Verlassen wird nach 5 Minuten Karenz '
                '(GPS-Drift-Toleranz) automatisch ausgestempelt. Funktioniert '
                'auch wenn die App komplett geschlossen ist.',
              ),
              _KeyValue(label: 'Zone betreten', value: 'Auto-Einstempeln (sofern nicht bereits eingestempelt)'),
              _KeyValue(label: 'Zone verlassen', value: '5 Min warten → Auto-Ausstempeln'),
              _KeyValue(label: 'Re-Entry binnen 5 Min', value: 'Karenz wird abgebrochen, kein Clock-out'),
              _KeyValue(label: 'Manueller Eintrag aktiv', value: 'Wird nie automatisch geschlossen'),
              _Hint(
                'Notiz/Tätigkeit zum Auto-Eintrag ergänzen: auf der Übersicht '
                'beim aktiven Eintrag „Notiz" antippen – Schnelldialog für '
                'Tätigkeitsbeschreibung. Kein Wechsel in den Einträge-Tab nötig.',
              ),
              _SubHeading('Watchdog – Vergessene Clock-outs'),
              _Para(
                'Wenn ein Auto-Eintrag noch offen ist und du seit mindestens '
                '30 Minuten in keiner Zone warst (z.B. weil GPS das Verlassen '
                'verpasst hat), erscheint eine Erinnerungs-Notification: '
                '„Noch eingestempelt? Seit Xh Ym …". Wiederholt sich alle '
                '15 Min als Update derselben Notification – kein Spam.',
              ),
              _Hint(
                'Manuelle Einträge werden NICHT vom Watchdog überwacht – '
                'wer manuell einstempelt (z.B. Homeoffice) bekommt keine '
                'Fehlalarme.',
              ),
              _SubHeading('Standorte für dieses Projekt'),
              _KeyValue(label: 'Gurk (Kräutergarten)', value: 'Radius ~300 m · AG: Gurktaler'),
              _KeyValue(label: 'Wien (Büro)', value: 'Radius ~150 m · AG: Gurktaler Wien'),
              _KeyValue(label: 'Homeoffice', value: 'Radius ~100 m · manuell einstempeln'),
              _SubHeading('Verhalten nach Geräteneustart'),
              _Para(
                'Wurde das Tracking aktiviert, läuft es nach jedem Neustart '
                'des Telefons automatisch weiter – ein eigener BootReceiver '
                'legt zuerst die Notification-Channels an und startet danach '
                'den Foreground-Service.',
              ),
              _Hint(
                'Hintergrund-GPS: Android fragt beim ersten Start nach '
                '"Immer erlauben". HyperOS/MIUI: Akkuoptimierung für '
                'Zeiterfassung auf "Keine Einschränkungen" setzen, sonst '
                'beendet das System den Service trotz Foreground-Notification.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.mail_outline,
            title: 'IMAP – E-Mail-Sortierung',
            children: [
              _Para(
                'Die App verbindet sich mit deinem IMAP-Postfach und '
                'verschiebt Mails von/an bekannten Adressen sowie Mails '
                'mit passenden Betreff-Schlüsselwörtern in definierte Ordner.',
              ),
              _SubHeading('Einrichtung'),
              _Step(number: '1', text: 'Einstellungen → E-Mail-Sortierung'),
              _Step(number: '2', text: 'IMAP-Server, Port (993/SSL), Zugangsdaten eintragen'),
              _Step(number: '3', text: '"Testen" prüft die Verbindung'),
              _Step(number: '4', text: 'Adressen der Gurktaler-Kontakte hinzufügen'),
              _Step(number: '5', text: 'Betreff-Schlüsselwörter hinzufügen (z. B. gurktaler, etiketten)'),
              _SubHeading('Was wird sortiert'),
              _KeyValue(label: 'Von/An Adresse', value: 'Alle Mails von/an Adressen in der Liste'),
              _KeyValue(label: 'Betreff-Match', value: 'Mails deren Betreff ein Schlüsselwort enthält'),
              _KeyValue(label: 'Thread-Antworten', value: 'Re: / Fwd: Mails bei Betreff-Match automatisch mit'),
              _Hint(
                'Synchronisierung läuft manuell ("Jetzt synchronisieren"). '
                'Einmal täglich reicht für saubere Dokumentation.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.laptop_outlined,
            title: 'Windows – App bauen',
            children: [
              _Para(
                'Die App läuft nativ auf Windows. Einmalig muss die '
                'Windows-Platform generiert werden, danach per build.ps1 bauen.',
              ),
              _SubHeading('Ersteinrichtung (einmalig)'),
              _Code(
                'cd app\n'
                'flutter create --platforms=windows .\n'
                'flutter pub get',
              ),
              _SubHeading('Build-Script (empfohlen)'),
              _Para('build.ps1 im Projektroot baut APK und/oder Windows-EXE und '
                  'legt die Ausgaben in builds\\ ab:'),
              _Code(
                '.\\build.ps1              # APK + Windows-ZIP\n'
                '.\\build.ps1 -ApkOnly     # nur APK\n'
                '.\\build.ps1 -WindowsOnly # nur Windows\n'
                '.\\build.ps1 -Clean       # mit flutter clean',
              ),
              _KeyValue(label: 'APK', value: 'builds\\zeiterfassung-YYYY-MM-DD.apk'),
              _KeyValue(label: 'Windows', value: 'builds\\zeiterfassung-YYYY-MM-DD-windows.zip'),
              _SubHeading('Manuell bauen'),
              _Code(
                '# Starten (Entwicklung):\n'
                'cd app && flutter run -d windows\n\n'
                '# Release:\n'
                'flutter build windows\n'
                '# → build\\windows\\x64\\runner\\Release\\',
              ),
              _SubHeading('Windows System-Tray'),
              _Para(
                'Die App minimiert sich per X-Button ins System-Tray '
                'statt zu beenden. Das Tray-Icon zeigt den aktuellen Status.',
              ),
              _KeyValue(label: 'Linksklick', value: 'Fenster öffnen'),
              _KeyValue(label: 'Rechtsklick', value: 'Menü: Öffnen / Ein-Ausstempeln / Beenden'),
              _KeyValue(label: 'Tooltip', value: 'Zeiterfassung · Seit 09:15 · Homeoffice'),
              _SubHeading('AppBar-Buttons (oben rechts)'),
              _KeyValue(label: 'Minimize-Icon', value: 'In Tray verstecken (gleich wie X-Button)'),
              _KeyValue(label: 'Close-Icon', value: 'App vollständig beenden (mit Bestätigung)'),
              _Hint(
                'X-Button und Minimize-Icon: App läuft im Hintergrund weiter, '
                'Tracking bleibt aktiv. Echtes Beenden nur über Tray-Menü → '
                '"Beenden" oder Close-Icon in der AppBar.',
              ),
              _SubHeading('Aktivitäts-Tracking auf Windows'),
              _Step(number: '1', text: 'App starten → Übersicht → Aktivitäts-Timeline'),
              _Step(number: '2', text: '"Start" drücken – läuft im Vordergrund'),
              _Step(number: '3', text: 'Aktives Fenster wird alle 30 Sek. geprüft'),
              _Step(number: '4', text: 'Whitelist-Treffer werden als Blöcke aufgezeichnet'),
              _Step(number: '5', text: 'Vorschläge erscheinen automatisch oben in der Timeline'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.phone_outlined,
            title: 'Telefonat schnell erfassen',
            children: [
              _Para(
                'Für Telefonate – besonders mit einem zweiten Arbeitgeber – '
                'gibt es auf der Übersicht einen direkten Schnellerfassungs-Button.',
              ),
              _Step(number: '1', text: 'Übersicht → „Telefonat erfassen" antippen'),
              _Step(number: '2', text: 'Dauer in 5-Minuten-Schritten einstellen (+/−)'),
              _Step(number: '3', text: 'Arbeitgeber wählen (Standard: aktiver Arbeitgeber)'),
              _Step(number: '4', text: 'Optionale Notiz eingeben → Speichern'),
              _Hint(
                'Start = jetzt minus Dauer, Ende = jetzt. '
                'Der Eintrag erscheint sofort in der Eintrags-Liste '
                'mit Tätigkeitsart „Telefonat".',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.sync_outlined,
            title: 'Automatische Synchronisierung',
            children: [
              _Para(
                'Die Synchronisierung mit dem NAS läuft vollautomatisch. '
                'Das NAS ist die Master-Quelle: gelöschte Arbeitgeber, '
                'Standorte und Whitelist-Änderungen propagieren auf alle Geräte.',
              ),
              _KeyValue(label: 'Beim App-Start', value: 'Sofort – NAS-Daten haben Vorrang'),
              _KeyValue(label: 'Nach Änderungen', value: '3 Sekunden nach Speichern/Löschen'),
              _KeyValue(label: 'Periodisch', value: 'Alle 15, 30 oder 60 Min. (einstellbar)'),
              _SubHeading('Was wird synchronisiert'),
              _KeyValue(label: 'Zeiteinträge', value: 'Bidirektional, last-write-wins'),
              _KeyValue(label: 'Arbeitgeber', value: 'Inkl. Löschungen (Soft-Delete)'),
              _KeyValue(label: 'Standorte', value: 'Inkl. Löschungen (Soft-Delete)'),
              _KeyValue(label: 'Projekte', value: 'Inkl. Löschungen (Soft-Delete)'),
              _KeyValue(label: 'Whitelist + Activity-Settings', value: 'LWW per Key – Gerät mit jüngster Änderung gewinnt'),
              _KeyValue(label: 'IMAP-Config', value: 'Bidirektional'),
              _SubHeading('Einstellungen'),
              _Step(number: '1', text: 'Einstellungen → Sync-Status → Intervall wählen (Aus / 15 / 30 / 60 Min.)'),
              _Step(number: '2', text: '"Jetzt" für manuellen Sofort-Sync – synchronisiert ALLES auf einmal'),
              _Hint(
                'Es gibt nur einen Sync-Befehl (Einstellungen → "Jetzt"). '
                'Er deckt Arbeitgeber, Standorte, Einträge und Whitelist '
                'gemeinsam ab. Nach erfolgreichem Sync werden alle Provider '
                'automatisch neu geladen – die UI zeigt neue Daten sofort, '
                'kein App-Neustart nötig.',
              ),
              _Hint(
                'Soft-Delete: Wird ein Arbeitgeber oder Standort gelöscht, '
                'erhält der Datensatz lokal ein deleted_at-Flag und wird beim '
                'nächsten Sync auch auf allen anderen Geräten entfernt.',
              ),
              _Hint(
                'Settings-LWW: Whitelist wird nur dann zum NAS hochgeladen, '
                'wenn du sie auf diesem Gerät tatsächlich geändert hast. '
                'Synchronisiert ein anderes Gerät später mit alten Werten, '
                'verlierst du deine Änderungen NICHT – das Gerät mit der '
                'jüngsten User-Änderung gewinnt.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            children: [
              _Para(
                'Vier Backup-Varianten in den Einstellungen unter "Datensicherung":',
              ),
              _SubHeading('Lokales Backup (JSON-Datei)'),
              _KeyValue(label: 'Backup erstellen', value: 'Speichert alle Tabellen + Settings als JSON'),
              _KeyValue(label: 'Backup wiederherstellen', value: 'Lädt eine JSON-Datei und ersetzt alle Daten'),
              _SubHeading('NAS-Backup'),
              _KeyValue(label: 'Backup auf NAS', value: 'Schickt aktuellen Stand an /api/backup'),
              _KeyValue(label: 'Backup vom NAS', value: 'Holt letzten NAS-Stand und stellt ihn wieder her'),
              _Para(
                'Auf dem NAS liegt immer nur das jeweils letzte Backup als '
                'backup_latest.json im DATA_DIR. Zusätzlich erstellt '
                'backup_synology.sh täglich ein DB-Backup mit 30 Tagen Aufbewahrung.',
              ),
              _Hint(
                'Restore überschreibt alle bestehenden lokalen Daten und '
                'setzt last_sync_at zurück. Beim nächsten Sync werden alle '
                'NAS-Daten neu gezogen – Einträge die zwischen Backup-Erstellung '
                'und Restore synct wurden, kommen automatisch zurück.',
              ),
              _Hint(
                'Praxis: Backup ist primär eine Notfall-Sicherung für den '
                'Fall dass der NAS nicht erreichbar ist. Solange der NAS läuft, '
                'ist er die "Single Source of Truth" – ein Restore alter '
                'Daten + Sync = du landest wieder beim NAS-Stand.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.history_outlined,
            title: 'Aktivitäts-Tracking & Vorschläge',
            children: [
              _Para(
                'Erfasst welche Apps und Fenster aktiv waren. '
                'Die Fusion-Engine analysiert die Daten automatisch und '
                'schlägt passende Zeiteinträge vor – jeder Vorschlag kann '
                'vor dem Speichern vollständig bearbeitet werden.',
              ),
              _SubHeading('Vorschläge (automatische Erkennung)'),
              _Para(
                'Beim Öffnen der Timeline werden Aktivitäts-Sessions '
                'mit bereits erfassten Telefonaten abgeglichen und zu '
                'Vorschlägen gruppiert. Jeder Vorschlag zeigt:',
              ),
              _KeyValue(label: 'Uhrzeit', value: 'Start – Ende · Dauer'),
              _KeyValue(label: 'Confidence', value: 'Wahrscheinlichkeit 0–100 % (grün / orange / grau)'),
              _KeyValue(label: 'Typ-Chip', value: 'Abgeleitete Tätigkeitsart (Telefonat, Homeoffice, …)'),
              _KeyValue(label: 'Signal-Chips', value: 'Welche Signale geflossen sind (Aktivität, Telefonat)'),
              _Step(
                number: '1',
                text: '"Bearbeiten & Übernehmen" → Eintrag-Formular öffnet sich vollständig editierbar',
              ),
              _Step(number: '2', text: 'Zeit, Tätigkeitsart, Pause, Notiz, Arbeitgeber anpassen'),
              _Step(number: '3', text: '"Speichern" → Eintrag wird angelegt, Vorschlag verschwindet'),
              _Step(
                number: '4',
                text: '"Verwerfen" → Vorschlag wird dauerhaft ausgeblendet (bleibt auch nach Neustart weg)',
              ),
              _Hint(
                'Vorschläge entstehen nur für Zeiträume die noch nicht durch '
                'bestehende Einträge abgedeckt sind (>50 % Überlappung → kein Vorschlag). '
                'Manuelles Nachbearbeiten ist immer möglich.',
              ),
              _SubHeading('Android – Nutzungsstatistiken'),
              _Step(number: '1', text: 'Übersicht → Aktivitäts-Timeline antippen'),
              _Step(
                number: '2',
                text: '"Berechtigung erteilen" → Einstellungen öffnen sich',
              ),
              _Step(
                number: '3',
                text: 'Zeiterfassung in der Liste suchen → Zugriff aktivieren',
              ),
              _Step(number: '4', text: 'Zurück in die App → Timeline lädt und Vorschläge erscheinen oben'),
              _Para(
                'Android zeigt App-Namen und Nutzungszeiträume für den '
                'gewählten Tag. Daten kommen direkt vom System '
                '(UsageStatsManager) – nichts wird separat gespeichert.',
              ),
              _SubHeading('Android – Quick-Settings-Tile'),
              _Step(number: '1', text: 'Schnelleinstellungen von oben nach unten wischen'),
              _Step(number: '2', text: 'Kacheln bearbeiten → "Aktivitäts-Timeline" hinzufügen'),
              _Step(number: '3', text: 'Tippen auf Kachel öffnet den Timeline-Screen direkt'),
              _SubHeading('Windows – Tracking'),
              _Step(number: '1', text: 'Timeline öffnen → "Start" drücken'),
              _Step(number: '2', text: 'Aktives Fenster wird alle 30 Sek. geloggt'),
              _Step(
                number: '3',
                text: 'Nach 5 Min. ohne Eingabe (Idle) pausiert die Aufzeichnung',
              ),
              _Step(number: '4', text: '"Stopp" → alle Blöcke erscheinen, Vorschläge werden generiert'),
              _SubHeading('Whitelist'),
              _Para('Nur Titel/Apps die einen Whitelist-Begriff enthalten werden aufgezeichnet.'),
              _KeyValue(label: 'Browser', value: 'Chrome, Firefox, Edge, Opera, Brave'),
              _KeyValue(label: 'Office', value: 'Word, Excel, PowerPoint, LibreOffice'),
              _KeyValue(label: 'PDF', value: 'Acrobat, Foxit, Sumatra'),
              _KeyValue(label: 'E-Mail', value: 'Outlook, Thunderbird'),
              _KeyValue(label: 'Komm.', value: 'Teams, Zoom, Slack'),
              _Hint(
                'Whitelist anpassen: Einstellungen → Aktivitäts-Tracking → '
                'Whitelist bearbeiten. Mindestdauer (Standard 3 Min.) und '
                'Leerlauf-Schwelle (Standard 5 Min.) sind ebenfalls konfigurierbar.',
              ),
              _SubHeading('Rohdaten manuell übernehmen'),
              _Para(
                'Unter den Vorschlägen sind alle Rohdaten-Blöcke sichtbar. '
                'Für feingranulare Kontrolle oder falls kein Vorschlag passt:',
              ),
              _Step(number: '1', text: 'Checkboxen der gewünschten Blöcke aktivieren'),
              _Step(
                number: '2',
                text: '"X übernehmen" → Eintrag-Formular öffnet sich mit Start/Ende vorausgefüllt',
              ),
              _Step(number: '3', text: 'Tätigkeitsart, Pause, Notiz anpassen → Speichern'),
              _Hint(
                'Datenschutz: Browser-URLs werden nicht erfasst. '
                'Nur Fenster-Titel bzw. App-Name. '
                'Windows-Protokoll kann über "Protokoll löschen" entfernt werden.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.folder_outlined,
            title: 'Projektzuordnung (Gurktaler AG)',
            children: const [
              _Para(
                'Zeiteinträge können einem Projekt zugeordnet werden. '
                'Die Projektzuordnung ist aktuell für Gurktaler AG verfügbar '
                'und erscheint im Formular sowie im Berichte-Screen.',
              ),
              _SubHeading('Projekte im Eintrag'),
              _Step(number: '1', text: 'Eintrag anlegen oder bearbeiten → Gurktaler-Sonderoptionen aufklappen'),
              _Step(number: '2', text: 'Projekt aus der Dropdown-Liste wählen (leer = kein Projekt)'),
              _Step(number: '3', text: 'Speichern – Projektzuordnung wird mit dem Eintrag synchronisiert'),
              _SubHeading('Projekte verwalten'),
              _Step(number: '1', text: 'Einstellungen → Arbeitgeber Gurktaler AG → Projekte'),
              _Step(number: '2', text: '„Projekt hinzufügen" – Name eingeben, bestätigen'),
              _Step(number: '3', text: 'Löschen über das Mülleimer-Icon (Soft-Delete, wird via NAS propagiert)'),
              _SubHeading('Berichte nach Projekt'),
              _Para(
                'Im Berichte-Screen erscheint unter der Monatstabelle eine '
                'Aufschlüsselung der Stunden nach Projekt. '
                '"Kein Projekt" fasst alle nicht zugeordneten Einträge zusammen.',
              ),
              _SubHeading('Vorhandene Projekte (Gurktaler AG)'),
              _KeyValue(label: 'Führungen', value: 'Besucherführungen Kräutergarten'),
              _KeyValue(label: 'Kräutergarten', value: 'Allgemeine Gartenarbeit'),
              _KeyValue(label: 'Mazeration', value: 'Mazerationsarbeiten'),
              _KeyValue(label: 'Kleinserie', value: 'Kleinserienfertigung (inkl. Pfau Brennerei)'),
              _KeyValue(label: 'Produktentwicklung', value: 'Neue Produkte, Rezepturen'),
              _KeyValue(label: 'Rezepturoptimierung', value: 'Verbesserung bestehender Rezepturen'),
              _KeyValue(label: 'Administration', value: 'Büro, Buchhaltung, Korrespondenz'),
              _Hint(
                'Projekte werden bidirektional mit dem NAS synchronisiert – '
                'einmal angelegt erscheinen sie auf allen Geräten. '
                'Ein auf Gerät A gelöschtes Projekt wird beim nächsten Sync '
                'auch auf Gerät B entfernt.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.description_outlined,
            title: 'Monatsberichte & Export',
            children: [
              _Para('Berichte → Monat wählen → XLSX exportieren.'),
              _KeyValue(label: 'Format', value: 'Excel (.xlsx) mit KW-Summen und Monatssumme'),
              _KeyValue(label: 'Import', value: 'Kompatibel mit Stempeluhr 2.1'),
              _KeyValue(label: 'Teilen', value: 'Direkt aus der App per Share-Dialog'),
              _Hint(
                'Für die Jahresauswertung jeden Monat exportieren oder '
                'alle Daten einmal jährlich vom NAS-Backend abfragen.',
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Baustein-Widgets ──────────────────────────────────────────────────────────

class _Section extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(widget.icon,
                color: Theme.of(context).colorScheme.primary),
            title: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }
}

class _SubHeading extends StatelessWidget {
  final String text;
  const _SubHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }
}

class _Code extends StatelessWidget {
  final String code;
  const _Code(this.code);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In Zwischenablage kopiert'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.75))),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline,
              size: 16,
              color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}
