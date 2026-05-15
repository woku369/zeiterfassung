import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../providers/suggestion_provider.dart';
import '../models/suggested_entry.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';
import 'entry_form_screen.dart';

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
    setState(() {
      _loading = true;
      _selected.clear();
    });
    final ap = context.read<ActivityProvider>();
    await ap.recheckPermission();
    // Silently request contacts permission if call log is already granted
    // (needed for live contact name lookup on older calls).
    if (Platform.isAndroid) {
      final contactsStatus = await Permission.contacts.status;
      if (!contactsStatus.isGranted) await Permission.contacts.request();
    }
    if (ap.hasPermission) {
      await ap.loadSessions(DateTime.now());
    }
    if (mounted) {
      await _generateSuggestions();
      setState(() => _loading = false);
    }
  }

  Future<void> _generateSuggestions() async {
    final ap = context.read<ActivityProvider>();
    final tp = context.read<TimeEntryProvider>();
    final ep = context.read<EmployerProvider>();
    final sp = context.read<SuggestionProvider>();

    // Ensure entries for selected day are loaded
    await tp.loadMonth(ap.selectedDate.year, ap.selectedDate.month);

    await sp.generate(
      ap.selectedDate,
      sessions: ap.sessions,
      existingEntries: tp.entries,
      activeEmployerId: ep.active?.id,
    );
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
    await ap.loadSessions(picked);
    if (mounted) await _generateSuggestions();
  }

  // ── Suggestion actions ─────────────────────────────────────────────────────

  Future<void> _acceptSuggestion(SuggestedEntry suggestion) async {
    // Pre-fill EntryFormScreen – user always has a chance to edit before saving
    final prefilled = suggestion.toPrefilledEntry();
    final dayType = HolidayService.instance.isHoliday(prefilled.date)
        ? DayType.holiday
        : prefilled.date.weekday == 6
            ? DayType.saturday
            : prefilled.date.weekday == 7
                ? DayType.sunday
                : DayType.workday;
    final entry = prefilled.copyWith(dayType: dayType);

    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EntryFormScreen(entry: entry, forceNew: true)),
    );
    // Regenerate after returning – user might have saved the entry
    if (mounted) await _generateSuggestions();
  }

  void _dismissSuggestion(String id) {
    context.read<SuggestionProvider>().dismiss(id);
  }

  // ── Call → entry ───────────────────────────────────────────────────────────

  Future<void> _acceptCall(dynamic call) async {
    final ap = context.read<ActivityProvider>();
    final ep = context.read<EmployerProvider>();
    final now = DateTime.now();
    final date = DateTime(call.startTime.year, call.startTime.month, call.startTime.day);
    final dayType = HolidayService.instance.isHoliday(date)
        ? DayType.holiday
        : date.weekday == 6 ? DayType.saturday
        : date.weekday == 7 ? DayType.sunday
        : DayType.workday;
    final entry = TimeEntry(
      id: '',
      date: date,
      startTime: call.startTime,
      endTime: call.isMissed ? call.startTime.add(const Duration(minutes: 1)) : call.endTime,
      breakMinutes: 0,
      workType: WorkType.phoneCall,
      dayType: dayType,
      note: call.title,
      employerId: ep.active?.id,
      createdAt: now,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryFormScreen(entry: entry, forceNew: true)),
    );
    if (mounted) await ap.markCallAdopted(call.id);
  }

  // ── Raw-session → entry ────────────────────────────────────────────────────

  Future<void> _createFromSelected() async {
    final ap = context.read<ActivityProvider>();
    final ep = context.read<EmployerProvider>();
    final selected =
        ap.sessions.where((s) => _selected.contains(s.id)).toList();
    if (selected.isEmpty) return;

    selected.sort((a, b) => a.startTime.compareTo(b.startTime));
    final start = selected.first.startTime;
    final end = selected.last.endTime;
    final titles = selected.map((s) => s.title).toSet().take(3).join(', ');
    final date = DateTime(start.year, start.month, start.day);
    final dayType = HolidayService.instance.isHoliday(date)
        ? DayType.holiday
        : date.weekday == 6
            ? DayType.saturday
            : date.weekday == 7
                ? DayType.sunday
                : DayType.workday;

    final prefilled = TimeEntry(
      id: '',
      date: date,
      startTime: start,
      endTime: end,
      dayType: dayType,
      note: titles,
      employerId: ep.active?.id,
      createdAt: DateTime.now(),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EntryFormScreen(entry: prefilled, forceNew: true)),
    );
    if (mounted) {
      final ap = context.read<ActivityProvider>();
      for (final s in selected) {
        await ap.markSessionAdopted(s.id);
      }
      setState(() => _selected.clear());
      await _generateSuggestions();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final sp = context.watch<SuggestionProvider>();
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
              tooltip: 'Protokoll löschen',
              onPressed: () => _confirmClear(ap),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Date + status bar ──────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
                if (ap.isSupported && !ap.hasPermission)
                  TextButton.icon(
                    icon:
                        const Icon(Icons.lock_open_outlined, size: 16),
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
            _WindowsTrackingBar(ap: ap),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !ap.hasPermission
                    ? _PermissionPlaceholder(
                        onRequest: () async {
                          await ap.openUsageSettings();
                          await Future.delayed(
                              const Duration(seconds: 2));
                          await ap.recheckPermission();
                          if (ap.hasPermission && mounted) await _load();
                        },
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        children: [
                          // ── Suggestions section ──────────────────────
                          if (sp.pending.isNotEmpty) ...[
                            _SectionHeader(
                              icon: Icons.auto_awesome_outlined,
                              label:
                                  'Vorschläge (${sp.pending.length})',
                              color: cs.primary,
                            ),
                            const SizedBox(height: 4),
                            ...sp.pending.map(
                              (s) => _SuggestionCard(
                                suggestion: s,
                                onAccept: () => _acceptSuggestion(s),
                                onDismiss: () =>
                                    _dismissSuggestion(s.id),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Call log section ─────────────────────────
                          if (Platform.isAndroid) ...[
                            if (!ap.hasCallLogPermission) ...[
                              _SectionHeader(
                                icon: Icons.phone_outlined,
                                label: 'Anrufe',
                                color: cs.tertiary,
                              ),
                              const SizedBox(height: 4),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.lock_outline, color: cs.tertiary),
                                  title: const Text('Berechtigung für Anruf-Log'),
                                  subtitle: const Text('Eingehende & ausgehende Anrufe anzeigen'),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final statuses = await [
                                        Permission.phone,
                                        Permission.contacts,
                                      ].request();
                                      if (statuses[Permission.phone]?.isGranted == true) {
                                        await ap.recheckCallLogPermission();
                                      } else {
                                        await openAppSettings();
                                      }
                                    },
                                    child: const Text('Erlauben'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else if (ap.calls.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.phone_outlined,
                                label: 'Anrufe (${ap.calls.length})',
                                color: cs.tertiary,
                              ),
                              const SizedBox(height: 4),
                              ...ap.calls.map((c) => _CallCard(
                                call: c,
                                adopted: ap.isCallAdopted(c.id),
                                onAccept: ap.isCallAdopted(c.id) ? null : () => _acceptCall(c),
                              )),
                              const SizedBox(height: 16),
                            ],
                          ],

                          // ── Raw sessions section ─────────────────────
                          if (ap.sessions.isEmpty)
                            _EmptyPlaceholder(
                              isWindows: _isWindows(),
                              isTracking: ap.isTracking,
                            )
                          else ...[
                            _SectionHeader(
                              icon: Icons.history_outlined,
                              label: 'Rohdaten',
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            ...ap.sessions.map((s) {
                              final checked  = _selected.contains(s.id);
                              final adopted  = ap.isSessionAdopted(s.id);
                              return Opacity(
                                opacity: adopted ? 0.45 : 1.0,
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  color: adopted
                                      ? cs.surfaceContainerLow
                                      : checked
                                          ? cs.primaryContainer
                                          : null,
                                  child: CheckboxListTile(
                                    value: checked,
                                    onChanged: adopted
                                        ? null
                                        : (v) => setState(() {
                                            if (v == true) {
                                              _selected.add(s.id);
                                            } else {
                                              _selected.remove(s.id);
                                            }
                                          }),
                                    title: Row(
                                      children: [
                                        if (adopted) ...[
                                          Icon(Icons.check_circle_outline,
                                              size: 14,
                                              color: cs.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            s.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: adopted
                                                ? TextStyle(
                                                    color: cs.onSurfaceVariant,
                                                    decoration:
                                                        TextDecoration.lineThrough)
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${tf.format(s.startTime)} – '
                                      '${tf.format(s.endTime)}'
                                      '  ·  ${_fmt(s.duration)}',
                                    ),
                                    secondary: _AppIcon(appName: s.appName),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createFromSelected,
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
        content: const Text(
            'Alle aufgezeichneten Aktivitäten dieses Tages löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ap.clearSessionsForDate(ap.selectedDate);
      if (mounted) {
        setState(() => _selected.clear());
        context.read<SuggestionProvider>().clearForDate();
      }
    }
  }

  String _fmt(Duration d) {
    if (d.isNegative) return '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  bool _isWindows() => Platform.isWindows;
}

// ── Suggestion card ─────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final SuggestedEntry suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tf = DateFormat('HH:mm');
    final pct = (suggestion.confidence * 100).round();
    final confidenceColor = pct >= 70
        ? Colors.green
        : pct >= 50
            ? Colors.orange
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.secondaryContainer.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  suggestion.signals.contains(SignalType.phoneCall)
                      ? Icons.phone_outlined
                      : Icons.work_outline,
                  size: 18,
                  color: cs.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tf.format(suggestion.startTime)} – '
                    '${tf.format(suggestion.endTime)}'
                    '  ·  ${_fmt(suggestion.duration)}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                        fontSize: 11,
                        color: confidenceColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // ── Sub-info ───────────────────────────────────────────────
            if (suggestion.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 26),
                child: Text(
                  suggestion.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 26),
              child: Row(
                children: [
                  _SignalChip(
                      label: suggestion.workType.label,
                      icon: Icons.label_outline),
                  if (suggestion.signals.contains(SignalType.phoneCall))
                    const _SignalChip(
                        label: 'Telefonat',
                        icon: Icons.phone_outlined),
                ],
              ),
            ),
            // ── Action buttons ─────────────────────────────────────────
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Verwerfen'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    textStyle: const TextStyle(fontSize: 13),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Bearbeiten & Übernehmen'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SignalChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Windows tracking bar ────────────────────────────────────────────────────

class _WindowsTrackingBar extends StatelessWidget {
  final ActivityProvider ap;
  const _WindowsTrackingBar({required this.ap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ap.isTracking
          ? cs.primaryContainer.withOpacity(0.5)
          : cs.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            ap.isTracking ? Icons.circle : Icons.circle_outlined,
            size: 12,
            color: ap.isTracking
                ? Colors.green
                : cs.onSurface.withOpacity(0.4),
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
                  }
                : () => ap.startTracking(),
            child: Text(ap.isTracking ? 'Stopp' : 'Start'),
          ),
        ],
      ),
    );
  }
}

// ── App icon ────────────────────────────────────────────────────────────────

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

// ── Placeholders ────────────────────────────────────────────────────────────

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
            const Text(
                'Nutzungsstatistiken benötigen eine Sonderberechtigung.',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Einstellungen → Apps → Zugriff auf Nutzungsdaten → '
              'Zeiterfassung aktivieren',
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
  const _EmptyPlaceholder(
      {required this.isWindows, required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isWindows
                  ? isTracking
                      ? 'Tracking läuft – Aktivitäten erscheinen nach '
                          '30 Sekunden.'
                      : 'Tracking starten um Aktivitäten aufzuzeichnen.'
                  : 'Keine Aktivitäten für diesen Tag.\n'
                      'Mindestdauer: '
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

// ── Call card ─────────────────────────────────────────────────────────────────

class _CallCard extends StatelessWidget {
  final dynamic call; // ActivityLog with isPhoneCall=true
  final bool adopted;
  final VoidCallback? onAccept;
  const _CallCard({required this.call, required this.adopted, required this.onAccept});

  String _typeLabel(int? type) => switch (type) {
    1 => '← eingehend',
    2 => '→ ausgehend',
    3 => '✕ verpasst',
    _ => 'Anruf',
  };

  String _fmt(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tf = DateFormat('HH:mm');
    final isMissed = call.callType == 3;
    return Opacity(
      opacity: adopted ? 0.45 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        color: adopted ? cs.surfaceContainerLow : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isMissed
                ? cs.errorContainer
                : cs.tertiaryContainer,
            child: Icon(
              isMissed ? Icons.phone_missed : Icons.phone,
              size: 18,
              color: isMissed ? cs.onErrorContainer : cs.onTertiaryContainer,
            ),
          ),
          title: Text(call.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: adopted ? TextDecoration.lineThrough : null,
                color: adopted ? cs.onSurfaceVariant : null,
              )),
          subtitle: Text(
            '${tf.format(call.startTime)}  ·  ${_fmt(call.duration)}'
            '  ·  ${_typeLabel(call.callType as int?)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: adopted
              ? Icon(Icons.check_circle_outline,
                  size: 18, color: cs.onSurfaceVariant)
              : isMissed
                  ? null
                  : TextButton(
                      onPressed: onAccept,
                      child: const Text('Übernehmen'),
                    ),
        ),
      ),
    );
  }
}
