import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../dev_config.dart';
import '../providers/employer_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/project_provider.dart';
import '../models/employer.dart';
import '../services/sync_service.dart';
import '../services/backup_service.dart';
import '../providers/sync_provider.dart';
import '../services/holiday_service.dart';
import '../services/activity_tracking_service.dart';
import '../providers/trip_provider.dart';
import '../providers/time_entry_provider.dart';
import '../database/database_helper.dart';
import '../models/time_entry.dart';
import 'locations_screen.dart';
import 'imap_screen.dart';
import 'trip_log_screen.dart';
import 'bluetooth_trip_screen.dart';
import 'activity_timeline_screen.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EmployerProvider>();
    final employer = ep.active;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── NAS-Verbindung ─────────────────────────────────────────────
          Text('NAS-Verbindung', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _NasCard(),
          const SizedBox(height: 20),

          // ── TerminMeister-Kopplung ─────────────────────────────────────
          Text('TerminMeister-Kopplung', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _TmCard(),
          const SizedBox(height: 20),

          // ── Arbeitgeber ────────────────────────────────────────────────
          Text('Arbeitgeber', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (employer != null)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(employer.name),
                    subtitle: Text('Wochensoll: ${employer.weeklyHours}h'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editEmployer(context, employer);
                        if (v == 'delete') _deleteEmployer(context, employer);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                        PopupMenuItem(value: 'delete', child: Text('Löschen')),
                      ],
                    ),
                    onTap: () => _editEmployer(context, employer),
                  ),
                ],
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Arbeitgeber hinzufügen'),
                onTap: () => _addEmployer(context),
              ),
            ),
          if (ep.employers.length > 1) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz,
                        color: Theme.of(context).colorScheme.secondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aktiver Arbeitgeber bestimmt welche Einträge, '
                        'Berichte und Importe angezeigt werden.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...ep.employers
                .where((e) => e.id != employer?.id)
                .map((e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: Text(e.name),
                        subtitle: Text(
                            '${e.weeklyHours}h/Woche · WJ ab ${_monthName(e.fiscalYearStartMonth)}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'switch') ep.setActive(e);
                            if (v == 'edit') _editEmployer(context, e);
                            if (v == 'delete') _deleteEmployer(context, e);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'switch', child: Text('Aktivieren')),
                            PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                            PopupMenuItem(value: 'delete', child: Text('Löschen')),
                          ],
                        ),
                        onTap: () => ep.setActive(e),
                      ),
                    )),
          ],
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Weiteren Arbeitgeber hinzufügen'),
              onTap: () => _addEmployer(context),
            ),
          ),

          // ── Projekte (nur Gurktaler AG) ───────────────────────────────
          if (employer != null &&
              employer.name.toLowerCase().contains('gurktaler')) ...[
            const SizedBox(height: 20),
            Text('Projekte', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ProjectsCard(employerId: employer.id),
          ],

          // ── Synchronisation ───────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Synchronisation', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _SyncCard(),

          // ── Automatische Erfassung ─────────────────────────────────────
          const SizedBox(height: 20),
          Text('Automatische Erfassung',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Standorte & Geofencing'),
                subtitle: const Text(
                    'Arbeitszeit beim Betreten definierter Standorte starten'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationsScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('E-Mail-Sortierung (IMAP)'),
                subtitle: const Text(
                    'Nachrichten bestimmter Adressen automatisch ablegen'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImapScreen()),
                ),
              ),
              if (Platform.isAndroid) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                _FahrtenbuchTile(),
              ],
            ]),
          ),

          // ── Geofencing-Log ────────────────────────────────────────────
          if (Platform.isAndroid) ...[
            const SizedBox(height: 20),
            Text('Diagnose', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const _GeofenceLogCard(),
          ],

          // ── Aktivitäts-Tracking ────────────────────────────────────────
          if (context.watch<ActivityProvider>().isSupported) ...[
            const SizedBox(height: 20),
            Text('Aktivitäts-Tracking',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ActivityTrackingCard(),
          ],

          // ── Feiertage ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Feiertage (Österreich)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _HolidayCard(),

          // ── Backup ────────────────────────────────────────────────────
          if (Platform.isWindows) ...[
            const SizedBox(height: 20),
            Text('Backup', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _BackupCard(),
          ],

          // ── NAS-Backups (alle Plattformen, nur wenn NAS konfiguriert) ──
          if (context.watch<SyncProvider>().hasNasConfig) ...[
            const SizedBox(height: 20),
            Text('NAS-Backups', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Geplante NAS-Backups'),
                subtitle: const Text('Täglich / Monatlich / Jährlich – ansehen & wiederherstellen'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final sp = context.read<SyncProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _NasBackupListScreen(
                        nasUrl: sp.nasUrl,
                        apiKey: sp.nasApiKey.isEmpty ? null : sp.nasApiKey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Datenpflege ───────────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Datenpflege', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const _DedupCard(),
          const SizedBox(height: 8),
          const _ForceResyncCard(),

          // ── Info ──────────────────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Info', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final build = snap.data?.buildNumber ?? '–';
              final version = snap.data?.version ?? '–';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zeiterfassung für Android & Windows'),
                      const SizedBox(height: 4),
                      Text('Version $version  ·  Build $build',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Keine automatischen Zuschlagsberechnungen.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Synchronisation via Tailscale + Next.js auf NAS.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return m >= 1 && m <= 12 ? names[m] : '$m';
  }

  Future<void> _deleteEmployer(BuildContext context, Employer employer) async {
    final ep = context.read<EmployerProvider>();
    if (ep.employers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens ein Arbeitgeber muss vorhanden sein.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Arbeitgeber löschen'),
        content: Text('"${employer.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ep.remove(employer.id);
    }
  }

  Future<void> _addEmployer(BuildContext context) async {
    final result = await _showEmployerDialog(context, null);
    if (result != null && context.mounted) {
      await context.read<EmployerProvider>().add(
            result['name']!,
            result['hours']!,
            fiscalYearStartMonth: result['fiscalMonth']!,
            vacationDaysPerYear: result['vacationDays'] ?? 25,
            monthlyGross: result['monthlyGross'] as double?,
          );
    }
  }

  Future<void> _editEmployer(BuildContext context, Employer employer) async {
    final result = await _showEmployerDialog(context, employer);
    if (result != null && context.mounted) {
      await context.read<EmployerProvider>().update(
            employer.copyWith(
              name: result['name'],
              weeklyHours: result['hours'],
              fiscalYearStartMonth: result['fiscalMonth'],
              vacationDaysPerYear: result['vacationDays'],
              monthlyGross: result['monthlyGross'] as double?,
            ),
          );
    }
  }

  Future<Map<String, dynamic>?> _showEmployerDialog(
      BuildContext context, Employer? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final hoursCtrl =
        TextEditingController(text: existing?.weeklyHours.toString() ?? '40');
    final vacationCtrl = TextEditingController(
        text: (existing?.vacationDaysPerYear ?? 25).toString());
    final grossCtrl = TextEditingController(
        text: existing?.monthlyGross?.toStringAsFixed(2) ?? '');
    int fiscalMonth = existing?.fiscalYearStartMonth ?? 4;
    const monthNames = [
      'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null
              ? 'Arbeitgeber hinzufügen'
              : 'Arbeitgeber bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Wochenstunden',
                    border: OutlineInputBorder(),
                    suffixText: 'h'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vacationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Urlaubstage/Jahr',
                    border: OutlineInputBorder(),
                    suffixText: 'Tage'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grossCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bruttogehalt/Monat (optional)',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                  helperText: 'Für So/FT-Pauschale-Berechnung',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: fiscalMonth,
                decoration: const InputDecoration(
                  labelText: 'Wirtschaftsjahr beginnt im',
                  border: OutlineInputBorder(),
                  helperText: 'z. B. April für WJ April–März',
                ),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                      value: i + 1, child: Text(monthNames[i])),
                ),
                onChanged: (v) => setState(() => fiscalMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final hours =
                    double.tryParse(hoursCtrl.text.replaceAll(',', '.')) ?? 40.0;
                final vacation = int.tryParse(vacationCtrl.text.trim()) ?? 25;
                if (name.isEmpty) return;
                Navigator.pop(context, {
                  'name': name,
                  'hours': hours,
                  'fiscalMonth': fiscalMonth,
                  'vacationDays': vacation,
                  'monthlyGross': grossCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(grossCtrl.text.trim().replaceAll(',', '.')),
                });
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element – kept for potential future per-employer override
  Future<void> _editNas(BuildContext context, Employer employer) async {
    final urlCtrl = TextEditingController(text: employer.nasUrl ?? '');
    final keyCtrl = TextEditingController(text: employer.nasApiKey ?? '');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('NAS-Verbindung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL (z.B. http://100.x.x.x:3000)',
                border: OutlineInputBorder(),
                helperText: 'Tailscale-IP des NAS',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API-Key (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, {'url': urlCtrl.text.trim(), 'key': keyCtrl.text.trim()}),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await context.read<EmployerProvider>().update(
        employer.copyWith(nasUrl: result['url'], nasApiKey: result['key']),
      );
    }
  }

  Future<void> _testConnection(
      BuildContext context, Employer employer) async {
    final nasUrl = employer.nasUrl;
    if (nasUrl == null || nasUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst NAS-URL konfigurieren')));
      return;
    }
    final ok = await SyncService.instance.testConnection(
      baseUrl: nasUrl,
      apiKey: employer.nasApiKey,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ok ? 'Verbindung erfolgreich' : 'Verbindung fehlgeschlagen'),
      backgroundColor:
          ok ? Colors.green : Theme.of(context).colorScheme.error,
    ));
  }
}

class _NasCard extends StatefulWidget {
  @override
  State<_NasCard> createState() => _NasCardState();
}

class _NasCardState extends State<_NasCard> {
  bool _testing = false;

  Future<void> _edit() async {
    final sp = context.read<SyncProvider>();
    final urlCtrl = TextEditingController(text: sp.nasUrl);
    final keyCtrl = TextEditingController(text: sp.nasApiKey);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('NAS-Verbindung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL (z. B. http://100.x.x.x:3000)',
                border: OutlineInputBorder(),
                helperText: 'Tailscale-IP des NAS',
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API-Key (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (kDebugMode && kDevNasUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                urlCtrl.text = kDevNasUrl;
                keyCtrl.text = kDevNasKey;
              },
              child: const Text('Dev'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, {'url': urlCtrl.text, 'key': keyCtrl.text}),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await context.read<SyncProvider>().saveNasConfig(
            result['url']!,
            result['key']!,
          );
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final ok = await context.read<SyncProvider>().testConnection();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Verbindung erfolgreich' : 'Verbindung fehlgeschlagen'),
      backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SyncProvider>();
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(
              sp.nasUrl.isEmpty ? 'Nicht konfiguriert' : sp.nasUrl,
              style: TextStyle(
                color: sp.nasUrl.isEmpty ? Colors.grey : null,
                fontSize: sp.nasUrl.isEmpty ? null : 13,
              ),
            ),
            subtitle:
                sp.nasUrl.isEmpty ? null : const Text('NAS-URL · Tailscale'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _edit,
          ),
          if (sp.hasNasConfig) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: _testing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_outlined),
              title: const Text('Verbindung testen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _testing ? null : _test,
            ),
          ],
        ],
      ),
    );
  }
}

// ── TerminMeister-Kopplung ────────────────────────────────────────────────────

class _TmCard extends StatefulWidget {
  @override
  State<_TmCard> createState() => _TmCardState();
}

class _TmCardState extends State<_TmCard> {
  Future<void> _edit() async {
    final sp = context.read<SyncProvider>();
    final urlCtrl = TextEditingController(text: sp.tmUrl);
    final keyCtrl = TextEditingController(text: sp.tmApiKey);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('TerminMeister-Kopplung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL (z.B. http://100.x.x.x:3005)',
                helperText: 'Tailscale-IP des NAS · Port 3005',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API-Key (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context,
                  {'url': urlCtrl.text.trim(), 'key': keyCtrl.text.trim()}),
              child: const Text('Speichern')),
        ],
      ),
    );
    if (result != null && mounted) {
      await context.read<SyncProvider>().saveTmConfig(result['url']!, result['key']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SyncProvider>();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: Text(
          sp.tmUrl.isEmpty ? 'Nicht konfiguriert' : sp.tmUrl,
          style: TextStyle(
            color: sp.tmUrl.isEmpty ? Colors.grey : null,
            fontSize: sp.tmUrl.isEmpty ? null : 13,
          ),
        ),
        subtitle: sp.tmUrl.isEmpty
            ? null
            : const Text('TerminMeister NAS · Port 3005'),
        trailing: const Icon(Icons.edit_outlined),
        onTap: _edit,
      ),
    );
  }
}

class _ActivityTrackingCard extends StatefulWidget {
  @override
  State<_ActivityTrackingCard> createState() => _ActivityTrackingCardState();
}

class _ActivityTrackingCardState extends State<_ActivityTrackingCard> {
  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Aktivitäts-Timeline öffnen'),
            subtitle: const Text('App-Nutzung als Zeiteintrag übernehmen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActivityTimelineScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Mindestdauer'),
            subtitle: Text('${ap.minDurationMinutes} Minuten'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: ap.minDurationMinutes > 1
                      ? () async {
                          ap.setMinDuration(ap.minDurationMinutes - 1);
                          await ap.saveSettings();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: ap.minDurationMinutes < 15
                      ? () async {
                          ap.setMinDuration(ap.minDurationMinutes + 1);
                          await ap.saveSettings();
                        }
                      : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.wifi_off_outlined),
            title: const Text('Leerlauf-Schwelle (Windows)'),
            subtitle: Text('${ap.idleThresholdMinutes} Minuten ohne Eingabe → Pause'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: ap.idleThresholdMinutes > 1
                      ? () async {
                          ap.setIdleThreshold(ap.idleThresholdMinutes - 1);
                          await ap.saveSettings();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: ap.idleThresholdMinutes < 30
                      ? () async {
                          ap.setIdleThreshold(ap.idleThresholdMinutes + 1);
                          await ap.saveSettings();
                        }
                      : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.filter_list_outlined),
            title: const Text('Whitelist bearbeiten'),
            subtitle: Text('${ap.whitelist.length} Einträge aktiv'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editWhitelist(context, ap),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Gerätename'),
            subtitle: Text(ap.deviceName),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editDeviceName(context, ap),
          ),
        ],
      ),
    );
  }

  Future<void> _editDeviceName(BuildContext context, ActivityProvider ap) async {
    final ctrl = TextEditingController(text: ap.deviceName);
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gerätename'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'z.B. Büro-PC, Tablet',
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved != null) await ap.setDeviceName(saved);
  }

  Future<void> _editWhitelist(BuildContext context, ActivityProvider ap) async {
    final ctrl = TextEditingController(text: ap.whitelist.join('\n'));
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Whitelist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ein Eintrag pro Zeile. Titel/App-Name muss einen '
              'dieser Begriffe enthalten (Groß-/Kleinschreibung egal).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 10,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(
                context,
                defaultWhitelist.join('\n')),
            child: const Text('Standard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (saved != null) {
      final list = saved
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      ap.setWhitelist(list);
      await ap.saveSettings();
    }
  }
}

class _HolidayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final holidays =
        HolidayService.instance.holidaysInMonth(now.year, now.month);
    final df = DateFormat('d. MMMM', 'de_AT');
    final upcoming = holidays
        .where((d) =>
            !d.isBefore(DateTime(now.year, now.month, now.day)))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feiertage diesen Monat',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const Text('Keine weiteren Feiertage',
                  style: TextStyle(color: Colors.grey))
            else
              ...upcoming.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.star_outline,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                            '${df.format(d)} – ${HolidayService.instance.holidayName(d) ?? ''}'),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Text(
              'Hinweis: Keine automatischen Zuschläge. Tagtyp bitte manuell setzen.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FahrtenbuchTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TripProvider>();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.directions_car_outlined),
          title: const Text('Fahrtenbuch'),
          subtitle: const Text('Fahrten ab 15 km/h automatisch aufzeichnen'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripLogScreen()),
                ),
                child: const Text('Einträge'),
              ),
              Switch(
                value: prov.trackingEnabled,
                onChanged: (v) => prov.setTrackingEnabled(v),
              ),
            ],
          ),
        ),
        if (prov.trackingEnabled) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.bluetooth_outlined),
            title: const Text('Bluetooth-Auslöser'),
            subtitle: const Text(
                'Aufzeichnung bei Verbindung mit definiertem Gerät starten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BluetoothTripScreen()),
            ),
          ),
        ],
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  static const _intervalOptions = [0, 15, 30, 60];
  static const _intervalLabels = ['Aus', '15 Min', '30 Min', '60 Min'];

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SyncProvider>();
    final tf = DateFormat('HH:mm', 'de_AT');

    String statusText;
    Color? statusColor;
    if (sp.isSyncing) {
      statusText = 'Synchronisierung läuft…';
      statusColor = null;
    } else if (sp.lastError != null) {
      statusText = 'Fehler: ${sp.lastError}';
      statusColor = Theme.of(context).colorScheme.error;
    } else if (sp.lastSyncAt != null) {
      statusText = 'Zuletzt: ${tf.format(sp.lastSyncAt!)}';
      statusColor = Colors.green;
    } else {
      statusText = sp.hasNasConfig ? 'Noch nicht synchronisiert' : 'Kein NAS konfiguriert';
      statusColor = Colors.grey;
    }

    final currentIdx = _intervalOptions.indexOf(sp.intervalMinutes);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: sp.isSyncing
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    sp.lastError != null
                        ? Icons.sync_problem_outlined
                        : Icons.sync_outlined,
                    color: statusColor,
                  ),
            title: Text(statusText,
                style: TextStyle(color: statusColor, fontSize: 14)),
            trailing: FilledButton.tonal(
              onPressed: sp.isSyncing || !sp.hasNasConfig
                  ? null
                  : () => sp.syncNow(),
              child: const Text('Jetzt'),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Auto-Sync'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: List.generate(
                    _intervalOptions.length,
                    (i) => ButtonSegment(
                      value: _intervalOptions[i],
                      label: Text(_intervalLabels[i],
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  selected: {currentIdx >= 0 ? sp.intervalMinutes : 30},
                  onSelectionChanged: (s) => sp.setInterval(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatefulWidget {
  @override
  State<_BackupCard> createState() => _BackupCardState();
}

class _ProjectsCard extends StatelessWidget {
  final String employerId;
  const _ProjectsCard({required this.employerId});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProjectProvider>();
    final projects = pp.forEmployer(employerId);

    return Card(
      child: Column(
        children: [
          ...projects.map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.folder_outlined, size: 20),
                title: Text(p.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Löschen',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Projekt löschen?'),
                        content: Text('"${p.name}" wirklich löschen?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Abbrechen')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Löschen')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<ProjectProvider>().remove(p.id);
                    }
                  },
                ),
              )),
          if (projects.isNotEmpty) const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, size: 20),
            title: const Text('Projekt hinzufügen'),
            onTap: () => _addProject(context, employerId),
          ),
        ],
      ),
    );
  }

  Future<void> _addProject(BuildContext context, String employerId) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neues Projekt'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Projektname',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
    if (name != null && context.mounted) {
      await context.read<ProjectProvider>().add(name, employerId);
    }
  }
}

class _BackupCardState extends State<_BackupCard> {
  bool _busy = false;

  Future<void> _exportToNas() async {
    final sp = context.read<SyncProvider>();
    if (!sp.hasNasConfig) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte NAS-URL in den Einstellungen konfigurieren.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await BackupService.instance.exportToNas(
        nasUrl: sp.nasUrl,
        apiKey: sp.nasApiKey.isEmpty ? null : sp.nasApiKey,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Backup auf NAS gespeichert.' : 'NAS-Backup fehlgeschlagen.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFromNas() async {
    final sp = context.read<SyncProvider>();
    if (!sp.hasNasConfig) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte NAS-URL in den Einstellungen konfigurieren.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('NAS-Backup wiederherstellen'),
        content: const Text(
          'Alle aktuellen Daten werden durch das letzte NAS-Backup ersetzt. Fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final success = await BackupService.instance.importFromNas(
        nasUrl: sp.nasUrl,
        apiKey: sp.nasApiKey.isEmpty ? null : sp.nasApiKey,
      );
      if (!mounted) return;
      if (success) {
        await context.read<EmployerProvider>().reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('NAS-Backup wiederhergestellt. App bitte neu starten.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kein NAS-Backup gefunden oder Fehler.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Backup auf NAS'),
            subtitle: const Text('Aktuellen Stand auf dem NAS sichern'),
            trailing: _busy
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_outlined),
            onTap: _busy ? null : _exportToNas,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Backup vom NAS'),
            subtitle: const Text('Letzten NAS-Stand wiederherstellen'),
            trailing: const Icon(Icons.download_outlined),
            onTap: _busy ? null : _importFromNas,
          ),
        ],
      ),
    );
  }
}

// ── Geofencing-Log ────────────────────────────────────────────────────────────

class _GeofenceLogCard extends StatelessWidget {
  const _GeofenceLogCard();

  Future<String> _logPath() async =>
      p.join(await getDatabasesPath(), 'geofence_log.txt');

  Future<String> _readLog() async {
    final file = File(await _logPath());
    if (!await file.exists()) return '(noch keine Einträge)';
    final lines = await file.readAsLines();
    // Letzte 300 Zeilen anzeigen
    final show = lines.length > 300 ? lines.sublist(lines.length - 300) : lines;
    return show.join('\n');
  }

  Future<void> _clearLog(BuildContext context) async {
    final file = File(await _logPath());
    if (await file.exists()) await file.delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log gelöscht')),
      );
    }
  }

  void _showLog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _GeofenceLogDialog(
        logContent: _readLog(),
        onClear: () => _clearLog(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: const Text('Geofencing-Log'),
        subtitle: const Text('GPS-Positionen, Zonen-Events, Clock-in/out'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLog(context),
      ),
    );
  }
}

class _GeofenceLogDialog extends StatefulWidget {
  final Future<String> logContent;
  final VoidCallback onClear;
  const _GeofenceLogDialog({required this.logContent, required this.onClear});

  @override
  State<_GeofenceLogDialog> createState() => _GeofenceLogDialogState();
}

class _GeofenceLogDialogState extends State<_GeofenceLogDialog> {
  late Future<String> _future;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = widget.logContent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Geofencing-Log'),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: FutureBuilder<String>(
          future: _future,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                child: SelectableText(
                  snap.data!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Kopieren'),
          onPressed: () async {
            final text = await widget.logContent;
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log in Zwischenablage'), duration: Duration(seconds: 2)),
              );
            }
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Löschen'),
          onPressed: () {
            widget.onClear();
            Navigator.pop(context);
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

// ── Datenpflege: Duplikate bereinigen ─────────────────────────────────────────

class _ForceResyncCard extends StatefulWidget {
  const _ForceResyncCard();
  @override
  State<_ForceResyncCard> createState() => _ForceResyncCardState();
}

class _ForceResyncCardState extends State<_ForceResyncCard> {
  bool _running = false;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vollständige Neusynchronisierung'),
        content: const Text(
          'Alle lokalen Einträge werden als unsynced markiert und beim nächsten Sync '
          'vollständig ans NAS übertragen.\n\n'
          'Das behebt Diskrepanzen zwischen Geräten, die durch ältere App-Versionen '
          'entstanden sein können.\n\n'
          'Nur auf dem Gerät mit den korrekten Daten ausführen!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Jetzt ausführen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _running = true);
    try {
      final count = await DatabaseHelper.instance.markAllUnsynced();
      if (!mounted) return;
      await context.read<SyncProvider>().syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count Einträge neu synchronisiert.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _running
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync_problem_outlined),
        title: const Text('Vollständige Neusynchronisierung'),
        subtitle: const Text('Alle Einträge erneut ans NAS übertragen'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _running ? null : _run,
      ),
    );
  }
}

class _DedupCard extends StatefulWidget {
  const _DedupCard();
  @override
  State<_DedupCard> createState() => _DedupCardState();
}

class _DedupCardState extends State<_DedupCard> {
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final groups = await DatabaseHelper.instance.findDuplicates();
      if (!mounted) return;
      if (groups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Mehrfacheinträge gefunden.')),
        );
        return;
      }
      await showDialog(
        context: context,
        builder: (_) => _DedupDialog(groups: groups),
      );
      // Reload entries after potential deletion
      if (mounted) {
        context.read<TimeEntryProvider>().refresh();
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _scanning
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.content_copy_outlined),
        title: const Text('Mehrfacheinträge suchen'),
        subtitle: const Text('Findet und entfernt doppelt erfasste Einträge'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _scanning ? null : _scan,
      ),
    );
  }
}

class _DedupDialog extends StatefulWidget {
  final List<List<TimeEntry>> groups;
  const _DedupDialog({required this.groups});
  @override
  State<_DedupDialog> createState() => _DedupDialogState();
}

class _DedupDialogState extends State<_DedupDialog> {
  bool _deleting = false;

  String _fmtEntry(TimeEntry e) {
    final d = '${e.date.day.toString().padLeft(2,'0')}.${e.date.month.toString().padLeft(2,'0')}.${e.date.year}';
    final start = '${e.startTime.hour.toString().padLeft(2,'0')}:${e.startTime.minute.toString().padLeft(2,'0')}';
    final end = e.endTime != null
        ? '–${e.endTime!.hour.toString().padLeft(2,'0')}:${e.endTime!.minute.toString().padLeft(2,'0')}'
        : '';
    final note = (e.note?.isNotEmpty == true) ? '  ${e.note}' : '';
    return '$d  $start$end$note';
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final deleted = await DatabaseHelper.instance.deleteDuplicates(widget.groups);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$deleted Mehrfacheinträge entfernt.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.groups.fold(0, (s, g) => s + g.length - 1);
    return AlertDialog(
      title: Text('${widget.groups.length} Gruppe${widget.groups.length == 1 ? '' : 'n'} gefunden'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.groups.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final group = widget.groups[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: group.asMap().entries.map((e) {
                final isFirst = e.key == 0;
                return Row(children: [
                  Icon(
                    isFirst ? Icons.check_circle_outline : Icons.delete_outline,
                    size: 16,
                    color: isFirst ? Colors.green : Colors.red.shade300,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _fmtEntry(e.value),
                      style: TextStyle(
                        fontSize: 12,
                        color: isFirst ? null : Colors.grey,
                        decoration: isFirst ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _deleting ? null : _delete,
          icon: _deleting
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.delete_sweep_outlined, size: 18),
          label: Text('$total Duplikat${total == 1 ? '' : 'e'} löschen'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
        ),
      ],
    );
  }
}

// ── NAS-Backup-Liste ──────────────────────────────────────────────────────────

class _NasBackupListScreen extends StatefulWidget {
  final String nasUrl;
  final String? apiKey;
  const _NasBackupListScreen({required this.nasUrl, this.apiKey});

  @override
  State<_NasBackupListScreen> createState() => _NasBackupListScreenState();
}

class _NasBackupListScreenState extends State<_NasBackupListScreen> {
  List<Map<String, dynamic>>? _backups;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await BackupService.instance.listNasBackups(
        nasUrl: widget.nasUrl,
        apiKey: widget.apiKey,
      );
      setState(() { _backups = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _restore(Map<String, dynamic> backup) async {
    final filename = backup['filename'] as String;
    final date = backup['date'] as String? ?? filename;
    final type = backup['type'] as String? ?? '';
    final typeLabel = type == 'daily' ? 'Täglich' : type == 'monthly' ? 'Monatlich' : 'Jährlich';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup wiederherstellen?'),
        content: Text(
          'Backup vom $date ($typeLabel) wiederherstellen?\n\n'
          'Alle lokalen Daten werden überschrieben!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await BackupService.instance.restoreFromNasBackup(
      nasUrl: widget.nasUrl,
      apiKey: widget.apiKey,
      filename: filename,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Backup wiederhergestellt. App bitte neu starten.'
          : 'Wiederherstellung fehlgeschlagen.'),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 5),
    ));
    if (success && mounted) {
      context.read<EmployerProvider>().reload();
    }
  }

  String _formatSize(dynamic sizeBytes) {
    if (sizeBytes == null) return '';
    final bytes = (sizeBytes as num).toInt();
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'daily': return 'Täglich';
      case 'monthly': return 'Monatlich';
      case 'yearly': return 'Jährlich';
      default: return type;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'daily': return Colors.blue;
      case 'monthly': return Colors.orange;
      case 'yearly': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NAS-Backups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Fehler: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Erneut versuchen')),
                      ],
                    ),
                  ),
                )
              : _backups == null || _backups!.isEmpty
                  ? const Center(child: Text('Keine Backups vorhanden'))
                  : _buildList(),
    );
  }

  Widget _buildList() {
    final backups = _backups!;
    // Gruppieren nach Typ
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final b in backups) {
      final type = (b['type'] as String?) ?? 'unknown';
      grouped.putIfAbsent(type, () => []).add(b);
    }

    final sections = <Widget>[];
    for (final type in ['yearly', 'monthly', 'daily']) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;
      sections.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          _typeLabel(type),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _typeColor(type),
          ),
        ),
      ));
      sections.add(Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            final date = b['date'] as String? ?? b['filename'] as String;
            final size = _formatSize(b['size_bytes']);
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    type == 'yearly'
                        ? Icons.calendar_today
                        : type == 'monthly'
                            ? Icons.calendar_month_outlined
                            : Icons.today_outlined,
                    color: _typeColor(type),
                  ),
                  title: Text(date),
                  subtitle: size.isNotEmpty ? Text(size) : null,
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Wiederherstellen'),
                    onPressed: () => _restore(b),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: sections,
    );
  }
}
