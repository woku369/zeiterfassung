import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/activity_provider.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  final Set<String> _selected = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ap = context.read<ActivityProvider>();
    await ap.recheckPermission();
    if (ap.hasPermission) {
      await ap.loadSessions(ap.selectedDate);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final ap = context.read<ActivityProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: ap.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('de', 'AT'),
    );
    if (picked == null || !mounted) return;
    setState(() => _selected.clear());
    await ap.loadSessions(picked);
  }

  Future<void> _createEntry() async {
    final ap = context.read<ActivityProvider>();
    final selected = ap.sessions.where((s) => _selected.contains(s.id)).toList();
    if (selected.isEmpty) return;

    selected.sort((a, b) => a.startTime.compareTo(b.startTime));
    final earliest = selected.first.startTime;
    final latest = selected.last.endTime;
    final titles = selected.map((s) => s.title).toSet().join(', ');

    final result = await _showConvertDialog(earliest, latest, titles);
    if (result == null || !mounted) return;

    final employer = context.read<EmployerProvider>().active;
    final date = DateTime(earliest.year, earliest.month, earliest.day);
    final dayType = HolidayService.instance.isHoliday(date)
        ? DayType.holiday
        : date.weekday == 6
            ? DayType.saturday
            : date.weekday == 7
                ? DayType.sunday
                : DayType.workday;

    final entry = TimeEntry(
      id: const Uuid().v4(),
      date: date,
      startTime: earliest,
      endTime: latest,
      breakMinutes: result['break'] as int,
      workType: result['workType'] as WorkType,
      dayType: dayType,
      note: result['note'] as String,
      employerId: employer?.id,
      createdAt: DateTime.now(),
    );

    await context.read<TimeEntryProvider>().addEntry(entry);
    if (!mounted) return;

    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zeiteintrag erstellt'), backgroundColor: Colors.green),
    );
  }

  Future<Map<String, dynamic>?> _showConvertDialog(
      DateTime start, DateTime end, String titles) {
    WorkType workType = WorkType.homeoffice;
    final noteCtrl = TextEditingController(text: titles);
    int breakMinutes = 0;
    final tf = DateFormat('HH:mm');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Zeiteintrag erstellen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tf.format(start)} – ${tf.format(end)}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                Text(
                  _formatDuration(end.difference(start) - Duration(minutes: breakMinutes)),
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WorkType>(
                  value: workType,
                  decoration: const InputDecoration(
                    labelText: 'Tätigkeitsart',
                    border: OutlineInputBorder(),
                  ),
                  items: WorkType.values
                      .where((t) => !t.isAbsence)
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => workType = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Pause: $breakMinutes min')),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: breakMinutes >= 5
                          ? () => setState(() => breakMinutes -= 5)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => breakMinutes += 5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notiz',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'workType': workType,
                'break': breakMinutes,
                'note': noteCtrl.text.trim(),
              }),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final tf = DateFormat('HH:mm');
    final df = DateFormat('EE, d. MMMM yyyy', 'de_AT');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitäts-Timeline'),
        actions: [
          if (ap.sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Sitzung löschen',
              onPressed: () => _confirmClear(ap),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Date + tracking status bar ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(df.format(ap.selectedDate),
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
                if (ap.isSupported && !ap.hasPermission)
                  TextButton.icon(
                    icon: const Icon(Icons.lock_open_outlined, size: 16),
                    label: const Text('Berechtigung'),
                    onPressed: () async {
                      await ap.openUsageSettings();
                      await Future.delayed(const Duration(seconds: 1));
                      await ap.recheckPermission();
                      if (ap.hasPermission && mounted) await _load();
                    },
                  )
                else if (ap.isSupported)
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    tooltip: 'Aktualisieren',
                    onPressed: _load,
                  ),
              ],
            ),
          ),

          // ── Windows tracking toggle ────────────────────────────────────
          if (_isWindows())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: ap.isTracking
                  ? cs.primaryContainer.withOpacity(0.5)
                  : cs.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    ap.isTracking ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: ap.isTracking ? Colors.green : cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ap.isTracking
                          ? 'Tracking läuft – Fenster werden aufgezeichnet'
                          : 'Tracking inaktiv',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: ap.isTracking
                        ? () async {
                            await ap.stopTracking();
                            if (mounted) setState(() {});
                          }
                        : () {
                            ap.startTracking();
                            setState(() {});
                          },
                    child: Text(ap.isTracking ? 'Stopp' : 'Start'),
                  ),
                ],
              ),
            ),

          // ── Session list ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !ap.hasPermission
                    ? _PermissionPlaceholder(onRequest: () async {
                        await ap.openUsageSettings();
                        await Future.delayed(const Duration(seconds: 2));
                        await ap.recheckPermission();
                        if (ap.hasPermission && mounted) await _load();
                      })
                    : ap.sessions.isEmpty
                        ? _EmptyPlaceholder(isWindows: _isWindows(), isTracking: ap.isTracking)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: ap.sessions.length,
                            itemBuilder: (_, i) {
                              final s = ap.sessions[i];
                              final checked = _selected.contains(s.id);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                color: checked ? cs.primaryContainer : null,
                                child: CheckboxListTile(
                                  value: checked,
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(s.id);
                                    } else {
                                      _selected.remove(s.id);
                                    }
                                  }),
                                  title: Text(s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    '${tf.format(s.startTime)} – ${tf.format(s.endTime)}'
                                    '  ·  ${_formatDuration(s.duration)}',
                                  ),
                                  secondary: _AppIcon(appName: s.appName),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      // ── FAB: convert selected ──────────────────────────────────────────
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createEntry,
              icon: const Icon(Icons.add_task),
              label: Text('${_selected.length} übernehmen'),
            )
          : null,
    );
  }

  Future<void> _confirmClear(ActivityProvider ap) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Protokoll löschen'),
        content: const Text('Alle aufgezeichneten Aktivitäten dieses Tages löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ap.clearSessionsForDate(ap.selectedDate);
      setState(() => _selected.clear());
    }
  }

  bool _isWindows() => Platform.isWindows;
}

class _AppIcon extends StatelessWidget {
  final String appName;
  const _AppIcon({required this.appName});

  @override
  Widget build(BuildContext context) {
    final icons = <String, IconData>{
      'chrome': Icons.public,
      'firefox': Icons.public,
      'edge': Icons.public,
      'opera': Icons.public,
      'brave': Icons.public,
      'word': Icons.description_outlined,
      'excel': Icons.table_chart_outlined,
      'powerpoint': Icons.slideshow_outlined,
      'libreoffice': Icons.description_outlined,
      'outlook': Icons.email_outlined,
      'thunderbird': Icons.email_outlined,
      'teams': Icons.groups_outlined,
      'zoom': Icons.video_call_outlined,
      'slack': Icons.chat_bubble_outline,
      'acrobat': Icons.picture_as_pdf_outlined,
      'foxit': Icons.picture_as_pdf_outlined,
      'sumatra': Icons.picture_as_pdf_outlined,
    };
    final lower = appName.toLowerCase();
    IconData? icon;
    for (final entry in icons.entries) {
      if (lower.contains(entry.key)) {
        icon = entry.value;
        break;
      }
    }
    return CircleAvatar(
      radius: 18,
      child: Icon(icon ?? Icons.computer_outlined, size: 18),
    );
  }
}

class _PermissionPlaceholder extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionPlaceholder({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Nutzungsstatistiken benötigen eine Sonderberechtigung.',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Einstellungen → Apps → Zugriff auf Nutzungsdaten → Zeiterfassung aktivieren',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Berechtigung erteilen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final bool isWindows;
  final bool isTracking;
  const _EmptyPlaceholder({required this.isWindows, required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isWindows
                  ? isTracking
                      ? 'Tracking läuft – Aktivitäten erscheinen nach 30 Sekunden.'
                      : 'Tracking starten um Aktivitäten aufzuzeichnen.'
                  : 'Keine Aktivitäten für diesen Tag.\nMindestdauer: '
                      '${context.read<ActivityProvider>().minDurationMinutes} Min.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
