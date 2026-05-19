import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/employer.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../models/entry_project_split.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../providers/project_provider.dart';
import '../services/holiday_service.dart';
import '../services/surcharge_service.dart';
import '../database/database_helper.dart';

class EntryFormScreen extends StatefulWidget {
  final TimeEntry? entry;
  // forceNew: treat entry as template for a new entry (e.g. from suggestions)
  final bool forceNew;
  const EntryFormScreen({super.key, this.entry, this.forceNew = false});
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
  String? _employerId;
  String? _projectId;
  bool _isSpecialHours = false;
  int _travelMinutes = 0;

  // Project splits: list of (projectId, minutesController) pairs
  final List<_SplitDraft> _splits = [];

  bool get _isNew => widget.entry == null || widget.forceNew;
  bool get _isAbsence => _workType.isAbsence;

  // Total entry minutes (null if end not set)
  int? get _entryMinutes {
    if (_endTime == null) return null;
    final start = _toDateTime(_startTime);
    var end = _toDateTime(_endTime!);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    final gross = end.difference(start).inMinutes;
    final bm = int.tryParse(_breakCtrl.text) ?? 0;
    return (gross - bm).clamp(0, 99999);
  }

  int get _allocatedMinutes =>
      _splits.fold(0, (s, d) => s + (int.tryParse(d.ctrl.text) ?? 0));

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
    _employerId = e?.employerId ??
        Provider.of<TimeEntryProvider>(context, listen: false).employerId;
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _kmCtrl = TextEditingController(text: e?.distanceKm?.toString() ?? '');
    _breakCtrl = TextEditingController(text: _breakMinutes.toString());
    _isSpecialHours = e?.isSpecialHours ?? false;
    _travelMinutes = e?.travelMinutes ?? 0;
    _projectId = e?.projectId;
    if (e != null && !widget.forceNew) {
      _loadSplits(e.id, fallbackProjectId: e.projectId);
    }
  }

  Future<void> _loadSplits(String entryId, {String? fallbackProjectId}) async {
    final saved = await DatabaseHelper.instance.getSplitsForEntry(entryId);
    if (!mounted) return;
    setState(() {
      if (saved.isNotEmpty) {
        _splits.addAll(saved.map((s) => _SplitDraft(
            projectId: s.projectId,
            minutes: s.minutes)));
      } else if (fallbackProjectId != null) {
        // Migrate single project_id → split with 0 min (user fills in)
        _splits.add(_SplitDraft(projectId: fallbackProjectId, minutes: 0));
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _kmCtrl.dispose();
    _breakCtrl.dispose();
    for (final d in _splits) d.ctrl.dispose();
    super.dispose();
  }

  Employer? get _selectedEmployer {
    if (_employerId == null) return null;
    final list = context.read<EmployerProvider>().employers;
    final idx = list.indexWhere((e) => e.id == _employerId);
    return idx == -1 ? null : list[idx];
  }

  bool get _isSurchargeEmployer =>
      SurchargeService.isSurchargeEmployer(_selectedEmployer);

  DayType _defaultDayType(DateTime d) {
    if (HolidayService.instance.isHoliday(d)) return DayType.holiday;
    if (d.weekday == 6) return DayType.saturday;
    if (d.weekday == 7) return DayType.sunday;
    return DayType.workday;
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
    final tp = context.read<TimeEntryProvider>();
    // For the legacy project_id field: keep single-project compat.
    final validSplits = _isSurchargeEmployer
        ? _splits.where((d) => d.projectId != null && (int.tryParse(d.ctrl.text) ?? 0) > 0).toList()
        : <_SplitDraft>[];
    final legacyProjectId = !_isSurchargeEmployer
        ? null
        : validSplits.length == 1
            ? validSplits.first.projectId
            : null;

    final entryId = _isNew ? const Uuid().v4() : widget.entry!.id;
    final entry = TimeEntry(
      id: entryId,
      date: _date,
      startTime: start,
      endTime: end,
      breakMinutes: bm,
      workType: _workType,
      dayType: _dayType,
      note: _noteCtrl.text.trim(),
      distanceKm: km,
      travelMinutes: _travelMinutes,
      employerId: _employerId,
      projectId: legacyProjectId,
      isSpecialHours: _isSurchargeEmployer && _isSpecialHours,
      isSynced: false,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
    );
    if (_isNew) {
      await tp.addEntry(entry);
      if (_workType == WorkType.sick && mounted) {
        final allEmployers = context.read<EmployerProvider>().employers;
        for (final emp in allEmployers) {
          if (emp.id == _employerId) continue;
          await tp.addEntry(entry.copyWith(
            id: const Uuid().v4(),
            employerId: emp.id,
          ));
        }
      }
    } else {
      await tp.updateEntry(entry);
    }

    // Save project splits
    if (_isSurchargeEmployer) {
      final splitModels = validSplits
          .map((d) => EntryProjectSplit.create(
                entryId: entryId,
                projectId: d.projectId!,
                minutes: int.parse(d.ctrl.text),
              ))
          .toList();
      await DatabaseHelper.instance.saveSplitsForEntry(entryId, splitModels);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final employers = context.read<EmployerProvider>().employers;
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
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
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
            if (employers.isNotEmpty)
              DropdownButtonFormField<String?>(
                value: _employerId,
                decoration: const InputDecoration(
                  labelText: 'Arbeitgeber',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Kein Arbeitgeber'),
                  ),
                  ...employers.map((e) => DropdownMenuItem<String?>(
                        value: e.id,
                        child: Text(e.name),
                      )),
                ],
                onChanged: (v) => setState(() => _employerId = v),
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
              if (_isSurchargeEmployer) ..._gurktalerExtras(),
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
                        _workType == WorkType.sick
                            ? 'Krankenstand – wird automatisch für alle Arbeitgeber eingetragen.'
                            : 'Abwesenheitstag – keine Zeiterfassung. Zählt nicht als Arbeitszeit.',
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

  Future<void> _editTravelMinutes() async {
    final ctrl = TextEditingController(
        text: _travelMinutes > 0 ? _travelMinutes.toString() : '');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fahrtzeit (Hin+Rück)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            suffixText: 'Min.',
            border: OutlineInputBorder(),
            hintText: 'z.B. 30 für Klagenfurt, 80 für Gurk',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text.trim()) ?? 0;
                Navigator.pop(context, v);
              },
              child: const Text('OK')),
        ],
      ),
    );
    if (result != null && result >= 0) setState(() => _travelMinutes = result);
  }

  List<Widget> _gurktalerExtras() {
    final isWeekendOrHoliday = _dayType != DayType.workday;

    // Samstag: Zuschlag nur ab 13:00 Uhr
    final endHour = _endTime?.hour ?? 0;
    final startHour = _startTime.hour;
    final satAfterCutoff = _dayType == DayType.saturday && endHour >= 13;
    final satStraddlesCutoff = satAfterCutoff && startHour < 13;

    final factor = (_isSpecialHours && _workType != WorkType.homeoffice)
        ? switch (_dayType) {
            DayType.saturday => satAfterCutoff ? 1.5 : 1.0,
            DayType.sunday   => 2.0,
            DayType.holiday  => 2.0,
            DayType.workday  => 1.0,
          }
        : 1.0;

    String surchargeLabel() {
      if (_workType == WorkType.homeoffice) return 'Homeoffice ist immer zuschlagsfrei.';
      if (!isWeekendOrHoliday) return 'Werktag → kein Zuschlag, gilt als Mehrarbeit.';
      if (_dayType == DayType.saturday) {
        if (!satAfterCutoff) return 'Samstag vor 13:00 – kein Zuschlag.';
        if (satStraddlesCutoff) return 'Samstag: vor 13:00 × 1.0 / ab 13:00 × 1.5';
        return 'Samstag ab 13:00 – Zuschlag × 1.5';
      }
      return 'Zuschlag laut Tagesart × ${factor.toStringAsFixed(1)}';
    }
    final projects = context.read<ProjectProvider>().forEmployer(_employerId);
    final totalMin = _entryMinutes;
    final allocMin = _allocatedMinutes;
    final restMin = totalMin != null ? (totalMin - allocMin) : null;

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.star_outline, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Text('Gurktaler-Sonderoptionen',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900)),
            ]),
            if (projects.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.folder_outlined, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text('Projekt-Aufschlüsselung',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900)),
              ]),
              const SizedBox(height: 6),
              ..._splits.asMap().entries.map((entry) {
                final idx = entry.key;
                final draft = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: projects.any((p) => p.id == draft.projectId)
                            ? draft.projectId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Projekt',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                        ),
                        items: projects
                            .map((p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(p.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => draft.projectId = v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        controller: draft.ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'Min.',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.orange.shade700,
                      onPressed: () => setState(() {
                        _splits[idx].ctrl.dispose();
                        _splits.removeAt(idx);
                      }),
                    ),
                  ]),
                );
              }),
              // Budget bar
              if (totalMin != null) ...[
                const SizedBox(height: 4),
                _SplitBudgetBar(
                    allocated: allocMin,
                    total: totalMin,
                    rest: restMin!),
              ] else if (allocMin > 0) ...[
                const SizedBox(height: 4),
                Text('Zugeordnet: ${_fmtMin(allocMin)}',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
              ],
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: projects.isEmpty
                    ? null
                    : () => setState(() => _splits.add(_SplitDraft())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Projekt hinzufügen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonderarbeitszeit (Führung u. ä.)',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              subtitle: Text(
                surchargeLabel(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
              ),
              value: _isSpecialHours,
              onChanged: (v) => setState(() => _isSpecialHours = v),
            ),
            const Divider(height: 16, color: Colors.orange),
            Row(children: [
              Icon(Icons.directions_car_outlined,
                  size: 18, color: Colors.grey.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _travelMinutes > 0
                      ? 'Fahrtzeit: $_travelMinutes Min. (Hin+Rück)'
                      : 'Fahrtzeit (Hin+Rück) hinzufügen:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
                ),
              ),
              if (_travelMinutes > 0) ...[
                IconButton(
                  iconSize: 18,
                  tooltip: 'Anpassen',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editTravelMinutes,
                ),
                IconButton(
                  iconSize: 18,
                  tooltip: 'Entfernen',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _travelMinutes = 0),
                ),
              ],
            ]),
            if (_travelMinutes == 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('+30 Min  (Klagenfurt)'),
                      onPressed: () => setState(() => _travelMinutes = 30),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('+80 Min  (Gurk)'),
                      onPressed: () => setState(() => _travelMinutes = 80),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Anderer Wert'),
                      onPressed: _editTravelMinutes,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];
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

// ── Project split helpers ─────────────────────────────────────────────────────

String _fmtMin(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
}

class _SplitDraft {
  String? projectId;
  final TextEditingController ctrl;

  _SplitDraft({String? projectId, int minutes = 0})
      : projectId = projectId,
        ctrl = TextEditingController(
            text: minutes > 0 ? minutes.toString() : '');

  void dispose() => ctrl.dispose();
}

class _SplitBudgetBar extends StatelessWidget {
  final int allocated;
  final int total;
  final int rest;
  const _SplitBudgetBar(
      {required this.allocated, required this.total, required this.rest});

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? (allocated / total).clamp(0.0, 1.0) : 0.0;
    final over = allocated > total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 6,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation(
                over ? Colors.red.shade400 : Colors.orange.shade600),
          ),
        ),
        const SizedBox(height: 3),
        Row(children: [
          Text('Zugeordnet: ${_fmtMin(allocated)} / ${_fmtMin(total)}',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
          const Spacer(),
          Text(
            over
                ? 'Überzogen: ${_fmtMin(allocated - total)}'
                : rest > 0
                    ? 'Rest: ${_fmtMin(rest)}'
                    : 'Vollständig',
            style: TextStyle(
                fontSize: 11,
                color: over
                    ? Colors.red.shade700
                    : rest > 0
                        ? Colors.grey.shade600
                        : Colors.green.shade700,
                fontWeight:
                    over ? FontWeight.w600 : FontWeight.normal),
          ),
        ]),
      ],
    );
  }
}
