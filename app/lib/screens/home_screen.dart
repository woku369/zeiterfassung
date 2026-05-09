import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../models/employer.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';
import '../services/tray_service.dart';
import 'entries_screen.dart';
import 'entry_form_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'activity_timeline_screen.dart';
import '../providers/activity_provider.dart';
import '../services/geofencing_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<TimeEntryProvider>().loadMonth(now.year, now.month);
    });
  }

  Future<void> _minimizeToTray() async {
    await windowManager.hide();
  }

  Future<void> _quitApp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('App beenden?'),
        content: const Text(
          'Die App wird vollständig geschlossen. '
          'Tracking im Hintergrund läuft erst nach Neustart wieder.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Beenden')),
        ],
      ),
    );
    if (ok != true) return;
    TrayService.instance.dispose();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isWindows
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 40,
              titleSpacing: 12,
              title: const Text('Zeiterfassung', style: TextStyle(fontSize: 14)),
              actions: [
                IconButton(
                  tooltip: 'In Tray minimieren',
                  icon: const Icon(Icons.minimize),
                  onPressed: _minimizeToTray,
                ),
                IconButton(
                  tooltip: 'App beenden',
                  icon: const Icon(Icons.close),
                  onPressed: _quitApp,
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: IndexedStack(
        index: _navIndex,
        children: const [_DashboardTab(), EntriesScreen(), ReportsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Übersicht'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Einträge'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Berichte'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _clockIn() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context, builder: (_) => const _ClockInDialog());
    if (result == null || !mounted) return;
    await context.read<TimeEntryProvider>().clockIn(
      workType: result['workType'] as WorkType,
      dayType: result['dayType'] as DayType,
    );
  }

  Future<void> _editActiveNote() async {
    final tp = context.read<TimeEntryProvider>();
    final active = tp.activeEntry;
    if (active == null) return;
    final ctrl = TextEditingController(text: active.note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notiz / Tätigkeit'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'z. B. Verschliesser sichten, Pfau Tel., Kennzeichnung Zirbe …',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await tp.updateEntry(active.copyWith(note: result));
  }

  Future<void> _clockOut() async {
    final tp = context.read<TimeEntryProvider>();
    final active = tp.activeEntry;
    // Pause vorschlagen wenn ≥5h und kein Homeoffice
    int suggestedBreak = 0;
    if (active != null) {
      final durationMinutes = DateTime.now().difference(active.startTime).inMinutes;
      if (durationMinutes >= 300 && active.workType != WorkType.homeoffice) {
        suggestedBreak = 30;
      }
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ClockOutDialog(initialBreakMinutes: suggestedBreak),
    );
    if (result == null || !mounted) return;
    await tp.clockOut(
      breakMinutes: result['breakMinutes'] as int,
      note: result['note'] as String,
    );
  }

  Future<void> _quickPhoneCall() async {
    final ep = context.read<EmployerProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PhoneCallDialog(
        initialEmployerId: ep.active?.id,
        employers: ep.employers,
      ),
    );
    if (result == null || !mounted) return;

    final now = DateTime.now();
    final durationMinutes = result['durationMinutes'] as int;
    final start = now.subtract(Duration(minutes: durationMinutes));
    final date = DateTime(start.year, start.month, start.day);
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
      startTime: start,
      endTime: now,
      breakMinutes: 0,
      workType: WorkType.phoneCall,
      dayType: dayType,
      note: result['note'] as String,
      employerId: result['employerId'] as String?,
      createdAt: now,
    );
    await context.read<TimeEntryProvider>().addEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Telefonat ($durationMinutes Min.) gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _hhmm(double h) {
    final hh = h.abs().floor();
    final mm = ((h.abs() - hh) * 60).round();
    return '${h < 0 ? '-' : ''}${hh}h ${mm.toString().padLeft(2, '0')}m';
  }

  String _hhmmss(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _openTimeline() async {
    await Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ActivityTimelineScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TimeEntryProvider>();
    final ep = context.watch<EmployerProvider>();
    final employer = ep.active;
    final ap = context.watch<ActivityProvider>();
    final now = DateTime.now();
    // Strip time component so Monday entries (stored as midnight) are not
    // excluded by a monday DateTime that still carries today's hour/minute.
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    final weeklyTarget = employer?.weeklyHours ?? 40.0;
    final weekHours = tp.totalHoursForWeek(monday);
    final monthHours = tp.totalHoursForMonth();
    final active = tp.activeEntry;
    final diff = weekHours - weeklyTarget;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy', 'de_AT').format(now)),
      ),
      body: RefreshIndicator(
        onRefresh: tp.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (ep.employers.length > 1)
              _EmployerChipBar(ep: ep),
            if (Platform.isAndroid)
              ValueListenableBuilder<List<String>>(
                valueListenable: GeofencingService.instance.activeZones,
                builder: (_, zones, __) {
                  if (zones.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Wrap(
                      spacing: 6,
                      children: zones.map((name) => Chip(
                        avatar: Icon(Icons.location_on,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        label: Text(name,
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
            Card(
              color: active != null ? cs.primaryContainer : cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    if (active != null) ...[
                      Text('Eingestempelt', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        _hhmmss(now.difference(active.startTime)),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontFamily: 'monospace'),
                      ),
                      Text(
                        'seit ${DateFormat('HH:mm').format(active.startTime)} · ${active.workType.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (active.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            active.note,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: cs.onPrimaryContainer.withOpacity(0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _editActiveNote,
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: Text(active.note.isEmpty ? 'Notiz' : 'Notiz bearbeiten'),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                            onPressed: _clockOut,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Ausstempeln'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        DateFormat('HH:mm:ss').format(now),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontFamily: 'monospace'),
                      ),
                      Text(DateFormat('EEEE, d. MMMM', 'de_AT').format(now),
                        style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _clockIn,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Einstempeln'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EntryFormScreen())),
                            icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                            label: const Text('Manuell'),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.onSurface.withOpacity(0.7),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _quickPhoneCall,
                            icon: const Icon(Icons.phone_outlined, size: 18),
                            label: const Text('Telefonat'),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.onSurface.withOpacity(0.7),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Woche', style: Theme.of(context).textTheme.titleSmall),
                        Text('${_hhmm(weekHours)} / ${_hhmm(weeklyTarget)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weeklyTarget > 0 ? (weekHours / weeklyTarget).clamp(0.0, 1.2) : 0,
                        minHeight: 10,
                        color: diff > 0 ? Colors.orange : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      diff.abs() < 0.016
                          ? 'Genau Soll'
                          : diff > 0
                              ? '+${_hhmm(diff)} Mehrarbeit'
                              : '${_hhmm(diff.abs())} noch offen',
                      style: TextStyle(
                        color: diff > 0 ? Colors.orange.shade700 : null,
                        fontWeight: diff.abs() > 0.016 ? FontWeight.w500 : null,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Monat gesamt'),
                trailing: Text(_hhmm(monthHours), style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            if (tp.totalKmForMonth() > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: const Text('Fahrtstrecke (Monat)'),
                  trailing: Text('${tp.totalKmForMonth().toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
            const SizedBox(height: 8),
            // ── Aktivitäts-Tracking ──────────────────────────────────────
            if (ap.isSupported)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ap.isTracking
                        ? Colors.green.withOpacity(0.15)
                        : null,
                    child: Icon(
                      Icons.history_outlined,
                      color: ap.isTracking ? Colors.green : null,
                    ),
                  ),
                  title: const Text('Aktivitäts-Timeline'),
                  subtitle: Text(
                    ap.isTracking
                        ? 'Tracking aktiv'
                        : 'App-Nutzung als Zeiteintrag übernehmen',
                    style: TextStyle(
                      color: ap.isTracking ? Colors.green : null,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openTimeline,
                ),
              ),
            const SizedBox(height: 16),
            if (tp.entries.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Letzte Einträge', style: Theme.of(context).textTheme.titleSmall),
              ),
              ...tp.entries.take(5).map((e) => _EntryTile(entry: e, compact: true)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployerChipBar extends StatelessWidget {
  final EmployerProvider ep;
  const _EmployerChipBar({required this.ep});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ep.employers.map((e) {
          final active = ep.active?.id == e.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.name),
              selected: active,
              onSelected: (_) => ep.setActive(e),
              avatar: active ? const Icon(Icons.check, size: 16) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TimeEntry entry;
  final bool compact;
  const _EntryTile({required this.entry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EE, d.M.', 'de_AT');
    final tf = DateFormat('HH:mm');
    final hh = entry.totalHours.floor();
    final mm = ((entry.totalHours - hh) * 60).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: compact,
        leading: CircleAvatar(
          radius: 20,
          child: Icon(_workTypeIcon(entry.workType), size: 18),
        ),
        title: Text(
          entry.workType.isAbsence
              ? '${df.format(entry.date)} · ${entry.workType.label}'
              : '${df.format(entry.date)} ${tf.format(entry.startTime)}–${entry.endTime != null ? tf.format(entry.endTime!) : '...'}',
        ),
        subtitle: entry.note.isNotEmpty ? Text(entry.note, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${hh}h ${mm.toString().padLeft(2, '0')}m',
              style: const TextStyle(fontWeight: FontWeight.w600)),
            if (entry.dayType != DayType.workday)
              Text(entry.dayType.label, style: const TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        ),
        onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => EntryFormScreen(entry: entry))),
      ),
    );
  }

  IconData _workTypeIcon(WorkType t) => switch (t) {
    WorkType.homeoffice => Icons.home_outlined,
    WorkType.phoneCall => Icons.phone_outlined,
    WorkType.email => Icons.email_outlined,
    WorkType.offsite => Icons.place_outlined,
    WorkType.travel => Icons.directions_car_outlined,
    WorkType.office => Icons.business_outlined,
    WorkType.other => Icons.work_outline,
    WorkType.vacation => Icons.beach_access_outlined,
    WorkType.sick => Icons.sick_outlined,
    WorkType.compensatoryLeave => Icons.event_available_outlined,
  };
}

class _ClockInDialog extends StatefulWidget {
  const _ClockInDialog();
  @override
  State<_ClockInDialog> createState() => _ClockInDialogState();
}

class _ClockInDialogState extends State<_ClockInDialog> {
  WorkType _workType = WorkType.homeoffice;
  late DayType _dayType;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (HolidayService.instance.isHoliday(now)) {
      _dayType = DayType.holiday;
    } else if (now.weekday == 6) {
      _dayType = DayType.saturday;
    } else if (now.weekday == 7) {
      _dayType = DayType.sunday;
    } else {
      _dayType = DayType.workday;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Einstempeln'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<WorkType>(
            value: _workType,
            decoration: const InputDecoration(labelText: 'Tätigkeitsart', border: OutlineInputBorder()),
            items: WorkType.values.where((t) => !t.isAbsence).map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
            onChanged: (v) => setState(() => _workType = v!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<DayType>(
            segments: DayType.values.map((d) => ButtonSegment(value: d, label: Text(d.label, style: const TextStyle(fontSize: 11)))).toList(),
            selected: {_dayType},
            onSelectionChanged: (s) => setState(() => _dayType = s.first),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, {'workType': _workType, 'dayType': _dayType}), child: const Text('Einstempeln')),
      ],
    );
  }
}

class _ClockOutDialog extends StatefulWidget {
  final int initialBreakMinutes;
  const _ClockOutDialog({this.initialBreakMinutes = 0});
  @override
  State<_ClockOutDialog> createState() => _ClockOutDialogState();
}

class _ClockOutDialogState extends State<_ClockOutDialog> {
  final _noteCtrl = TextEditingController();
  late int _breakMinutes;

  @override
  void initState() {
    super.initState();
    _breakMinutes = widget.initialBreakMinutes;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ausstempeln'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pause: $_breakMinutes min', style: Theme.of(context).textTheme.bodyMedium),
              ),
              IconButton(icon: const Icon(Icons.remove), onPressed: _breakMinutes >= 5 ? () => setState(() => _breakMinutes -= 5) : null),
              IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _breakMinutes += 5)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Notiz (optional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, {'breakMinutes': _breakMinutes, 'note': _noteCtrl.text.trim()}), child: const Text('Ausstempeln')),
      ],
    );
  }
}

class _PhoneCallDialog extends StatefulWidget {
  final String? initialEmployerId;
  final List<Employer> employers;
  const _PhoneCallDialog({required this.initialEmployerId, required this.employers});

  @override
  State<_PhoneCallDialog> createState() => _PhoneCallDialogState();
}

class _PhoneCallDialogState extends State<_PhoneCallDialog> {
  int _minutes = 15;
  late String? _employerId;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _employerId = widget.initialEmployerId;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(Duration(minutes: _minutes));
    final tf = DateFormat('HH:mm');

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.phone_outlined, size: 20),
          SizedBox(width: 8),
          Text('Telefonat erfassen'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tf.format(start)} – ${tf.format(now)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Dauer:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _minutes > 5 ? () => setState(() => _minutes -= 5) : null,
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_minutes Min.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _minutes += 5),
              ),
            ],
          ),
          if (widget.employers.length > 1) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _employerId,
              decoration: const InputDecoration(
                labelText: 'Arbeitgeber',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Kein Arbeitgeber')),
                ...widget.employers.map((e) => DropdownMenuItem<String?>(
                      value: e.id,
                      child: Text(e.name),
                    )),
              ],
              onChanged: (v) => setState(() => _employerId = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Notiz (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
            autofocus: widget.employers.length <= 1,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'durationMinutes': _minutes,
            'employerId': _employerId,
            'note': _noteCtrl.text.trim(),
          }),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
