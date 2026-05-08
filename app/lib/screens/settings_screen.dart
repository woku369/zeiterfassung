import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'locations_screen.dart';
import 'imap_screen.dart';
import 'activity_timeline_screen.dart';
import 'package:intl/intl.dart';

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
            ]),
          ),

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

          // ── Info ──────────────────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Info', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zeiterfassung für Android & Windows'),
                  SizedBox(height: 4),
                  Text('Keine automatischen Zuschlagsberechnungen.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Synchronisation via Tailscale + Next.js auf NAS.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
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
            ),
          );
    }
  }

  Future<Map<String, dynamic>?> _showEmployerDialog(
      BuildContext context, Employer? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final hoursCtrl =
        TextEditingController(text: existing?.weeklyHours.toString() ?? '40');
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
                if (name.isEmpty) return;
                Navigator.pop(context,
                    {'name': name, 'hours': hours, 'fiscalMonth': fiscalMonth});
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
    final ok = await SyncService.instance.testConnection(
      baseUrl: employer.nasUrl!,
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
        ],
      ),
    );
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
