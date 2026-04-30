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
              _Step(number: '1', text: 'Arbeitgeber unter Einstellungen anlegen'),
              _Step(number: '2', text: 'NAS-URL eintragen (oder ohne Sync nutzen)'),
              _Step(number: '3', text: 'Standorte definieren für automatische Erfassung'),
              _Step(number: '4', text: 'IMAP-Konto einrichten für E-Mail-Sortierung'),
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
                'Das Backend ist eine Next.js-App die als Docker-Container '
                'auf dem NAS läuft. Sie nimmt Sync-Anfragen der App entgegen '
                'und speichert Einträge in einer SQLite-Datenbank.',
              ),
              _SubHeading('Docker Compose (Synology)'),
              _Code(
                'services:\n'
                '  zeiterfassung:\n'
                '    image: node:20-alpine\n'
                '    working_dir: /app\n'
                '    volumes:\n'
                '      - ./backend:/app\n'
                '      - ./data:/app/data\n'
                '    command: sh -c "npm install && npm start"\n'
                '    ports:\n'
                '      - "3000:3000"\n'
                '    restart: unless-stopped',
              ),
              _SubHeading('In der App konfigurieren'),
              _Step(number: '1', text: 'Einstellungen → Arbeitgeber → NAS-URL'),
              _Step(number: '2', text: 'URL: http://100.x.x.x:3000'),
              _Step(number: '3', text: 'API-Key eintragen (falls in .env gesetzt)'),
              _Step(number: '4', text: '"Verbindung testen" bestätigt die Erreichbarkeit'),
              _SubHeading('API-Key setzen (optional aber empfohlen)'),
              _Code('# backend/.env\nAPI_KEY=dein-geheimes-passwort'),
              _Hint('Ohne API-Key ist das Backend für jeden im Tailscale-Netz '
                  'erreichbar. Bei mehreren Personen im Netzwerk empfehlenswert.'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.devices_outlined,
            title: 'Mehrere Geräte – Workflow',
            children: [
              _Para(
                'Die App funktioniert auf jedem Gerät unabhängig. '
                'Synchronisierung ist optional und erfolgt manuell.',
              ),
              _SubHeading('Empfohlener Workflow'),
              _Step(
                number: '1',
                text: 'Auf Gerät A Einträge erfassen (auch offline möglich)',
              ),
              _Step(
                number: '2',
                text: 'Einträge → Sync: sendet ungesyncte Einträge ans NAS',
              ),
              _Step(
                number: '3',
                text: 'Auf Gerät B: Sync → holt alle Einträge vom NAS',
              ),
              _Hint(
                'Konflikte: Einträge mit derselben ID werden per Upsert '
                'überschrieben – immer der zuletzt gesyncte Stand gewinnt.',
              ),
              _SubHeading('Geräte-Übersicht'),
              _KeyValue(key: 'Android', value: 'GPS, Geofencing, Benachrichtigungen'),
              _KeyValue(key: 'Windows', value: 'System-Tray (nach Platform-Setup), IMAP-Sync'),
              _KeyValue(key: 'NAS', value: 'Zentraler Datenspeicher, immer online'),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Geofencing – Standorte',
            children: [
              _Para(
                'Die App erkennt automatisch, wenn du einen definierten '
                'Standort betrittst oder verlässt, und schlägt vor, '
                'die Arbeitszeit zu starten bzw. zu beenden.',
              ),
              _SubHeading('Standort anlegen'),
              _Step(number: '1', text: 'Einstellungen → Automatische Erfassung → Standorte'),
              _Step(number: '2', text: '"Aktuelle Position verwenden" vor Ort antippen'),
              _Step(number: '3', text: 'Radius je nach Gelände: 100–500 m'),
              _Step(number: '4', text: 'Tracking oben rechts aktivieren'),
              _SubHeading('Standorte für dieses Projekt'),
              _KeyValue(key: 'Gurk (Kräutergarten)', value: 'Radius ~300 m · Arbeitstyp: Vor-Ort'),
              _KeyValue(key: 'Wien (Büro)', value: 'Radius ~150 m · Arbeitstyp: Büro'),
              _KeyValue(key: 'Salzburg (Lohnabfüller)', value: 'Radius ~200 m · Arbeitstyp: Dienstreise'),
              _Hint(
                'Hintergrund-GPS: Android fragt beim ersten Start nach '
                '"Immer erlauben". Ohne diese Berechtigung funktioniert '
                'Geofencing nur wenn die App geöffnet ist.',
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
              _KeyValue(key: 'Von/An Adresse', value: 'Alle Mails von/an Adressen in der Liste'),
              _KeyValue(key: 'Betreff-Match', value: 'Mails deren Betreff ein Schlüsselwort enthält'),
              _KeyValue(key: 'Thread-Antworten', value: 'Re: / Fwd: Mails bei Betreff-Match automatisch mit'),
              _Hint(
                'Synchronisierung läuft manuell ("Jetzt synchronisieren"). '
                'Einmal täglich reicht für saubere Dokumentation.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.laptop_outlined,
            title: 'Windows Tray-Widget (Setup)',
            children: [
              _Para(
                'Das Windows Tray-Widget ermöglicht 1-Klick-Zeiterfassung '
                'aus der Taskleiste heraus, ohne die App zu öffnen. '
                'Einmalige Einrichtung erforderlich.',
              ),
              _SubHeading('Windows-Platform aktivieren'),
              _Code(
                '# Im Verzeichnis /app ausführen:\n'
                'flutter create --platforms=windows .',
              ),
              _Step(number: '1', text: 'Obigen Befehl im app/-Verzeichnis ausführen'),
              _Step(
                number: '2',
                text: 'In tray_service.dart die auskommentierten Zeilen aktivieren',
              ),
              _Step(
                number: '3',
                text: 'Ein 32×32 Pixel Icon als assets/tray_icon.ico hinzufügen',
              ),
              _Step(number: '4', text: 'flutter build windows'),
              _Hint(
                'Der Tray-Service ist im Code bereits vollständig vorbereitet '
                '(lib/services/tray_service.dart). Nur die Platform-Initialisierung '
                'fehlt noch.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _Section(
            icon: Icons.description_outlined,
            title: 'Monatsberichte & Export',
            children: [
              _Para('Berichte → Monat wählen → XLSX exportieren.'),
              _KeyValue(key: 'Format', value: 'Excel (.xlsx) mit KW-Summen und Monatssumme'),
              _KeyValue(key: 'Import', value: 'Kompatibel mit Stempeluhr 2.1'),
              _KeyValue(key: 'Teilen', value: 'Direkt aus der App per Share-Dialog'),
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
  final String key;
  final String value;
  const _KeyValue({required this.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(key,
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
