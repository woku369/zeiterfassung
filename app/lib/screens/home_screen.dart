import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import 'entries_screen.dart';
import 'entry_form_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: const [_DashboardTab(), EntriesScreen(), ReportsScreen(), SettingsScreen(), HelpScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Übersicht'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Einträge'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Berichte'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Einstellungen'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Handbuch'),
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

  Future<void> _clockOut() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context, builder: (_) => const _ClockOutDialog());
    if (result == null || !mounted) return;
    await context.read<TimeEntryProvider>().clockOut(
      breakMinutes: result['breakMinutes'] as int,
      note: result['note'] as String,
    );
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TimeEntryProvider>();
    final employer = context.watch<EmployerProvider>().active;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weeklyTarget = employer?.weeklyHours ?? 40.0;
    final dailyTarget = weeklyTarget / 5;
    final daysWorked = now.weekday.clamp(1, 5);
    final weekTarget = dailyTarget * daysWorked;
    final weekHours = tp.totalHoursForWeek(monday);
    final monthHours = tp.totalHoursForMonth();
    final active = tp.activeEntry;
    final diff = weekHours - weekTarget;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy', 'de_AT').format(now)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Manuell hinzufügen',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: tp.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                        onPressed: _clockOut,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Ausstempeln'),
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
                        Text('${_hhmm(weekHours)} / ${_hhmm(weekTarget)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weekTarget > 0 ? (weekHours / weekTarget).clamp(0.0, 1.2) : 0,
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
          '${df.format(entry.date)} ${tf.format(entry.startTime)}–${entry.endTime != null ? tf.format(entry.endTime!) : '...'}',
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
    WorkType.offsite => Icons.place_outlined,
    WorkType.travel => Icons.directions_car_outlined,
    WorkType.office => Icons.business_outlined,
    WorkType.other => Icons.work_outline,
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
    final wd = DateTime.now().weekday;
    _dayType = wd == 6 ? DayType.saturday : wd == 7 ? DayType.sunday : DayType.workday;
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
            items: WorkType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
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
  const _ClockOutDialog();
  @override
  State<_ClockOutDialog> createState() => _ClockOutDialogState();
}

class _ClockOutDialogState extends State<_ClockOutDialog> {
  final _noteCtrl = TextEditingController();
  int _breakMinutes = 0;

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
