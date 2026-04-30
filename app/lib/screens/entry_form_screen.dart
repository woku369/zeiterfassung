import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../providers/time_entry_provider.dart';
import '../services/holiday_service.dart';

class EntryFormScreen extends StatefulWidget {
  final TimeEntry? entry;
  const EntryFormScreen({super.key, this.entry});
  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late int _breakMinutes;
  late WorkType _workType;
  late DayType _dayType;
  late TextEditingController _noteCtrl;
  late TextEditingController _kmCtrl;
  late TextEditingController _breakCtrl;

  bool get _isNew => widget.entry == null;
  bool get _isAbsence => _workType.isAbsence;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final now = DateTime.now();
    _date = e?.date ?? DateTime(now.year, now.month, now.day);
    _startTime = e != null ? TimeOfDay.fromDateTime(e.startTime) : TimeOfDay.fromDateTime(now);
    _endTime = e?.endTime != null ? TimeOfDay.fromDateTime(e!.endTime!) : null;
    _breakMinutes = e?.breakMinutes ?? 0;
    _workType = e?.workType ?? WorkType.homeoffice;
    _dayType = e?.dayType ?? _defaultDayType(_date);
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _kmCtrl = TextEditingController(text: e?.distanceKm?.toString() ?? '');
    _breakCtrl = TextEditingController(text: _breakMinutes.toString());
  }

  DayType _defaultDayType(DateTime d) {
    if (HolidayService.instance.isHoliday(d)) return DayType.holiday;
    if (d.weekday == 6) return DayType.saturday;
    if (d.weekday == 7) return DayType.sunday;
    return DayType.workday;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _kmCtrl.dispose();
    _breakCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('de', 'AT'),
    );
    if (d != null) setState(() { _date = d; _dayType = _defaultDayType(d); });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : (_endTime ?? TimeOfDay.now()),
    );
    if (t == null) return;
    setState(() { if (isStart) _startTime = t; else _endTime = t; });
  }

  DateTime _toDateTime(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final bm = _isAbsence ? 0 : (int.tryParse(_breakCtrl.text) ?? 0);
    final km = _isAbsence ? null : double.tryParse(_kmCtrl.text.replaceAll(',', '.'));
    final start = _toDateTime(_startTime);
    DateTime? end;
    if (!_isAbsence && _endTime != null) {
      end = _toDateTime(_endTime!);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    }
    final entry = TimeEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      date: _date,
      startTime: start,
      endTime: end,
      breakMinutes: bm,
      workType: _workType,
      dayType: _dayType,
      note: _noteCtrl.text.trim(),
      distanceKm: km,
      travelMinutes: widget.entry?.travelMinutes ?? 0,
      isSynced: false,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
    );
    final tp = context.read<TimeEntryProvider>();
    if (_isNew) {
      await tp.addEntry(entry);
    } else {
      await tp.updateEntry(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, d. MMMM yyyy', 'de_AT');
    final holidayName = HolidayService.instance.holidayName(_date);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Neuer Eintrag' : 'Eintrag bearbeiten'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Löschen',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Löschen?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  await context.read<TimeEntryProvider>().deleteEntry(widget.entry!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Datum'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(df.format(_date)),
                  if (holidayName != null)
                    Text(holidayName,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500)),
                ],
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: _dayTypeTileColor(context),
            ),
            const SizedBox(height: 8),
            // Day type
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<DayType>(
                    segments: DayType.values.map((d) =>
                      ButtonSegment(value: d, label: Text(d.label, style: const TextStyle(fontSize: 11)))
                    ).toList(),
                    selected: {_dayType},
                    onSelectionChanged: (s) => setState(() => _dayType = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Work type
            DropdownButtonFormField<WorkType>(
              value: _workType,
              decoration: const InputDecoration(
                labelText: 'Tätigkeitsart',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(),
              ),
              items: WorkType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Row(
                  children: [
                    if (t.isAbsence) ...[
                      Icon(Icons.calendar_today_outlined, size: 14,
                          color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                    ],
                    Text(t.label),
                  ],
                ),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _workType = v);
              },
            ),
            const SizedBox(height: 12),
            if (!_isAbsence) ...[
              // Times
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Beginn',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeTile(
                      label: 'Ende',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false),
                      placeholder: 'noch offen',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Break
              TextFormField(
                controller: _breakCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pause (Minuten)',
                  prefixIcon: Icon(Icons.pause_circle_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Distance
              TextFormField(
                controller: _kmCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fahrtstrecke (km)',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Nur für Fahrten relevant',
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Absence info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Abwesenheitstag – keine Zeiterfassung. Zählt nicht als Arbeitszeit.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isNew ? 'Speichern' : 'Änderungen speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Color? _dayTypeTileColor(BuildContext context) {
    return switch (_dayType) {
      DayType.saturday => Colors.amber.shade50,
      DayType.sunday => Colors.orange.shade50,
      DayType.holiday => Colors.red.shade50,
      DayType.workday => Theme.of(context).colorScheme.surfaceContainerLow,
    };
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final String? placeholder;
  const _TimeTile({required this.label, required this.time, required this.onTap, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final display = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : placeholder ?? '--:--';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(display, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
