import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/employer_provider.dart';
import '../models/employer.dart';
import '../services/sync_service.dart';
import '../services/holiday_service.dart';
import 'locations_screen.dart';
import 'imap_screen.dart';
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
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editEmployer(context, employer),
                  ),
                  ListTile(
                    leading: const Icon(Icons.link_outlined),
                    title: const Text('NAS-URL (Next.js)'),
                    subtitle: Text(
                      employer.nasUrl?.isNotEmpty == true
                          ? employer.nasUrl!
                          : 'Nicht konfiguriert',
                      style: TextStyle(
                        color: employer.nasUrl?.isNotEmpty == true
                            ? null
                            : Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editNas(context, employer),
                  ),
                  if (employer.nasUrl?.isNotEmpty == true)
                    ListTile(
                      leading: const Icon(Icons.wifi_tethering_outlined),
                      title: const Text('Verbindung testen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _testConnection(context, employer),
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
                        trailing: FilledButton.tonal(
                          onPressed: () => ep.setActive(e),
                          child: const Text('Wechseln'),
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

          // ── Feiertage ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          Text('Feiertage (Österreich)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _HolidayCard(),

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
