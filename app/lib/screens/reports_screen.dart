import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../providers/sync_provider.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/terminmeister_service.dart';
import '../database/database_helper.dart';
import '../models/time_entry.dart';
import '../models/employer.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';
import '../services/surcharge_service.dart';
import '../providers/project_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EmployerProvider>();
    final employer = ep.active;
    final others = ep.employers.where((e) => e.id != employer?.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Berichte'),
              if (employer != null)
                Text(
                  employer.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.65),
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          actions: [
            if (others.isNotEmpty)
              PopupMenuButton<Employer>(
                tooltip: 'Arbeitgeber wechseln',
                icon: const Icon(Icons.swap_horiz),
                onSelected: (e) => ep.setActive(e),
                itemBuilder: (_) => others
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Row(children: [
                            const Icon(Icons.business_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(e.name),
                          ]),
                        ))
                    .toList(),
              ),
          ],
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Monat'),
            Tab(icon: Icon(Icons.trending_up_outlined), text: 'Wirtschaftsjahr'),
          ]),
        ),
        body: const TabBarView(children: [
          _MonthTab(),
          _FiscalYearTab(),
        ]),
      ),
    );
  }
}

// ── Monatstab (bisheriger Inhalt) ────────────────────────────────────────────

class _MonthTab extends StatefulWidget {
  const _MonthTab();
  @override
  State<_MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<_MonthTab> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _exportXlsx() async {
    setState(() => _exporting = true);
    try {
      final tp = context.read<TimeEntryProvider>();
      final employer = context.read<EmployerProvider>().active;
      final file = await ExportService.instance.exportMonth(
        entries: List.from(tp.entries),
        year: tp.selectedYear,
        month: tp.selectedMonth,
        employerName: employer?.name ?? '',
        weeklyHours: employer?.weeklyHours ?? 40,
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Zeiterfassung Export');
    } catch (e) {
      if (mounted) _showError('Export fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importXlsx() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) {
        setState(() => _importing = false);
        return;
      }
      final employer = context.read<EmployerProvider>().active;
      final importResult = ImportService.instance.importFromXlsx(
          result.files.single.bytes!,
          employerId: employer?.id);
      if (!mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import-Vorschau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (importResult.period != null) ...[
                Text('Zeitraum: ${importResult.period}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
              ],
              Text('${importResult.entries.length} Einträge gefunden'),
              const SizedBox(height: 4),
              const Text(
                'Bereits vorhandene Einträge (gleicher Tag + Uhrzeit) werden übersprungen.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (importResult.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${importResult.errors.length} Warnung(en):',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ...importResult.errors.take(5).map((e) => Text(e,
                    style: const TextStyle(fontSize: 12, color: Colors.orange))),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen')),
            if (importResult.entries.isNotEmpty)
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Importieren')),
          ],
        ),
      );

      if (ok == true && mounted) {
        // Use insertOrUpdateEntries for idempotent import (stable IDs = no dupes)
        await DatabaseHelper.instance.insertOrUpdateEntries(importResult.entries);
        await context.read<TimeEntryProvider>().refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${importResult.entries.length} Einträge importiert${importResult.period != null ? ' (${importResult.period})' : ''}')));
        }
      }
    } catch (e) {
      if (mounted) _showError('Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TimeEntryProvider>();
    final employer = context.watch<EmployerProvider>().active;
    final entries = tp.entries;
    final monthHours = tp.totalHoursForMonth();
    final weeklyTarget = employer?.weeklyHours ?? 40.0;
    final monthTarget = weeklyTarget * 4.33;
    final diff = monthHours - monthTarget;
    final byType = <WorkType, double>{};
    for (final e in entries) {
      if (!e.workType.isAbsence) {
        byType[e.workType] = (byType[e.workType] ?? 0) + e.totalHours;
      }
    }
    final df = DateFormat('MMMM yyyy', 'de_AT');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Monatsnavigation ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final prev =
                    DateTime(tp.selectedYear, tp.selectedMonth - 1);
                tp.loadMonth(prev.year, prev.month);
              },
            ),
            Text(df.format(DateTime(tp.selectedYear, tp.selectedMonth)),
                style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final next =
                    DateTime(tp.selectedYear, tp.selectedMonth + 1);
                tp.loadMonth(next.year, next.month);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── Monatszusammenfassung ─────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Monatszusammenfassung',
                    style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                _SummaryRow('Ist-Stunden', _fmtH(monthHours)),
                _SummaryRow('Soll-Stunden', _fmtH(monthTarget)),
                _SummaryRow(
                  diff >= 0 ? 'Mehrarbeit' : 'Minderstunden',
                  '${diff >= 0 ? '+' : ''}${_fmtH(diff)}',
                  color: diff > 1
                      ? Colors.orange.shade700
                      : diff < -1
                          ? Colors.red
                          : null,
                ),
                _SummaryRow('Einträge', '${entries.length}'),
                if (tp.totalKmForMonth() > 0)
                  _SummaryRow('Fahrtstrecke',
                      '${tp.totalKmForMonth().toStringAsFixed(1)} km'),
                ...() {
                  final vacation = entries.where((e) => e.workType == WorkType.vacation).length;
                  final sick = entries.where((e) => e.workType == WorkType.sick).length;
                  final za = entries.where((e) => e.workType == WorkType.compensatoryLeave).length;
                  return [
                    if (vacation > 0) _SummaryRow('Urlaubstage', '$vacation', color: Colors.blue.shade600),
                    if (sick > 0) _SummaryRow('Krankenstandstage', '$sick', color: Colors.orange.shade700),
                    if (za > 0) _SummaryRow('Zeitausgleich', '$za', color: Colors.green.shade700),
                  ];
                }(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (byType.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Nach Tätigkeitsart',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  ...byType.entries
                      .map((kv) => _SummaryRow(kv.key.label, _fmtH(kv.value))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        _ProjectBreakdownCard(entries: entries, employer: employer),
        _TmFuehrungenCard(year: tp.selectedYear, month: tp.selectedMonth),
        const SizedBox(height: 12),
        if (entries.any((e) => e.dayType != DayType.workday))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Besondere Tage',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  ...DayType.values
                      .where((d) => d != DayType.workday)
                      .map((d) {
                    final h = entries
                        .where((e) => e.dayType == d)
                        .fold(0.0, (s, e) => s + e.totalHours);
                    if (h == 0) return const SizedBox.shrink();
                    return _SummaryRow(d.label, _fmtH(h),
                        color: Colors.orange.shade700);
                  }),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text('Aktionen', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.download_outlined,
          title: 'XLSX exportieren',
          subtitle: 'Monatsansicht als Excel-Datei',
          loading: _exporting,
          onTap: _exportXlsx,
        ),
        _ActionTile(
          icon: Icons.upload_outlined,
          title: 'XLSX importieren',
          subtitle: 'Aus Stempeluhr 2.1 oder kompatiblem Format',
          loading: _importing,
          onTap: _importXlsx,
        ),
      ],
    );
  }
}

// ── TerminMeister-Führungen ────────────────────────────────────────────────────

class _TmFuehrungenCard extends StatefulWidget {
  final int year;
  final int month;
  const _TmFuehrungenCard({required this.year, required this.month});

  @override
  State<_TmFuehrungenCard> createState() => _TmFuehrungenCardState();
}

class _TmFuehrungenCardState extends State<_TmFuehrungenCard> {
  List<TmAppointment>? _appointments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_TmFuehrungenCard old) {
    super.didUpdateWidget(old);
    if (old.year != widget.year || old.month != widget.month) _load();
  }

  Future<void> _load() async {
    final sp = context.read<SyncProvider>();
    if (!sp.hasTmConfig) {
      if (mounted) setState(() => _appointments = []);
      return;
    }
    final month = '${widget.year}-${widget.month.toString().padLeft(2, '0')}';
    final result = await TerminMeisterService.instance.fetchMonth(
      sp.tmUrl,
      month,
      apiKey: sp.tmApiKey.isEmpty ? null : sp.tmApiKey,
    );
    if (mounted) setState(() => _appointments = result);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SyncProvider>();
    if (!sp.hasTmConfig) return const SizedBox.shrink();

    final apps = _appointments;
    if (apps == null) return const SizedBox.shrink(); // loading

    // Group by date
    final byDate = <String, List<TmAppointment>>{};
    for (final a in apps) {
      if (a.startDate == null) continue;
      final key = DateFormat('d. MMMM', 'de_AT').format(a.startDate!);
      (byDate[key] ??= []).add(a);
    }
    if (byDate.isEmpty) return const SizedBox.shrink();

    final totalParticipants =
        apps.fold<int>(0, (s, a) => s + a.participantCount);

    return Column(
      children: [
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('Führungen & Events',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const Divider(),
                ...byDate.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: e.value
                                  .map((a) => Text(
                                        _fmtAppointment(a),
                                        style: const TextStyle(fontSize: 13),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Text(
                  '${apps.length} ${apps.length == 1 ? 'Führung' : 'Führungen'}'
                  '${totalParticipants > 0 ? ' · $totalParticipants Teilnehmer gesamt' : ''}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtAppointment(TmAppointment a) {
    final parts = <String>[a.title];
    if (a.group != null && a.group!.isNotEmpty) parts.add(a.group!);
    if (a.participantCount > 0) parts.add('${a.participantCount} Pers.');
    return parts.join(' · ');
  }
}

// ── Projektauswertung ─────────────────────────────────────────────────────────

class _ProjectBreakdownCard extends StatelessWidget {
  final List<TimeEntry> entries;
  final Employer? employer;
  const _ProjectBreakdownCard({required this.entries, required this.employer});

  @override
  Widget build(BuildContext context) {
    if (employer == null) return const SizedBox.shrink();
    if (!employer!.name.toLowerCase().contains('gurktaler')) return const SizedBox.shrink();

    final projects = context.watch<ProjectProvider>().forEmployer(employer!.id);
    if (projects.isEmpty) return const SizedBox.shrink();

    // Build map project_id → hours, also collect unassigned hours
    final byProject = <String, double>{};
    double unassigned = 0;
    for (final e in entries) {
      if (e.workType.isAbsence) continue;
      if (e.projectId != null &&
          projects.any((p) => p.id == e.projectId)) {
        byProject[e.projectId!] = (byProject[e.projectId!] ?? 0) + e.totalHours;
      } else {
        unassigned += e.totalHours;
      }
    }

    final hasData = byProject.isNotEmpty || unassigned > 0;
    if (!hasData) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Nach Projekt', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...projects
                .where((p) => byProject.containsKey(p.id))
                .map((p) => _SummaryRow(p.name, _fmtH(byProject[p.id]!))),
            if (unassigned > 0)
              _SummaryRow('Kein Projekt', _fmtH(unassigned),
                  color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// ── Wirtschaftsjahr-Tab ───────────────────────────────────────────────────────

class _FiscalYearTab extends StatefulWidget {
  const _FiscalYearTab();
  @override
  State<_FiscalYearTab> createState() => _FiscalYearTabState();
}

class _FiscalYearTabState extends State<_FiscalYearTab> {
  // Pivot year = year in which the fiscal year starts.
  late int _pivotYear;
  bool _loading = false;
  // Month index 0..11 → actual hours for that month.
  final List<double> _monthHours = List.filled(12, 0.0);
  // Month index → Vertragsäquivalent (Ist × Zuschlagsfaktor).
  final List<double> _monthEquivalent = List.filled(12, 0.0);
  bool _showEquivalent = false;
  int _vacationDays = 0;
  int _sickDays = 0;
  int _compensatoryDays = 0;

  @override
  void initState() {
    super.initState();
    final employer = _employer;
    final now = DateTime.now();
    _pivotYear = employer?.fiscalYearStart(now).year ?? now.year;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadFiscalYear());
  }

  Employer? get _employer =>
      context.read<EmployerProvider>().active;

  int get _fiscalStartMonth =>
      _employer?.fiscalYearStartMonth ?? 4;

  DateTime get _fyStart =>
      DateTime(_pivotYear, _fiscalStartMonth);

  DateTime get _fyEnd =>
      DateTime(_pivotYear + 1, _fiscalStartMonth);

  String get _fyLabel {
    final endYear = (_pivotYear + 1) % 100;
    return 'WJ $_pivotYear/${endYear.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFiscalYear() async {
    setState(() => _loading = true);
    final from = _fyStart;
    final to = DateTime(_fyEnd.year, _fyEnd.month, 0); // last day before end
    final entries =
        await DatabaseHelper.instance.getEntriesForDateRange(from, to,
            employerId: _employer?.id);
    for (var i = 0; i < 12; i++) {
      _monthHours[i] = 0.0;
      _monthEquivalent[i] = 0.0;
    }
    _vacationDays = 0;
    _sickDays = 0;
    _compensatoryDays = 0;
    final isSurcharge = SurchargeService.isSurchargeEmployer(_employer);
    _showEquivalent = isSurcharge;
    for (final e in entries) {
      final monthIndex = (e.date.year * 12 + e.date.month - 1) -
          (_fyStart.year * 12 + _fyStart.month - 1);
      if (monthIndex >= 0 && monthIndex < 12) {
        _monthHours[monthIndex] += e.totalHours;
        _monthEquivalent[monthIndex] +=
            SurchargeService.equivalentHours(e, isSurchargeEmployer: isSurcharge);
      }
      if (e.workType == WorkType.vacation) _vacationDays++;
      if (e.workType == WorkType.sick) _sickDays++;
      if (e.workType == WorkType.compensatoryLeave) _compensatoryDays++;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _prevYear() {
    setState(() => _pivotYear--);
    _loadFiscalYear();
  }

  void _nextYear() {
    setState(() => _pivotYear++);
    _loadFiscalYear();
  }

  @override
  Widget build(BuildContext context) {
    final employer = context.watch<EmployerProvider>().active;
    final weeklyHours = employer?.weeklyHours ?? 0.0;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Jahr-Navigation ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: _prevYear,
                      icon: const Icon(Icons.chevron_left)),
                  Text(_fyLabel,
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                      onPressed: _nextYear,
                      icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 4),
              if (weeklyHours > 0)
                Center(
                  child: Text(
                    'Wochensoll: ${weeklyHours}h  ·  Jahressoll: ${_fmtH(weeklyHours * 52)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                ),
              const SizedBox(height: 16),
              // ── Monatstabelle ────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(children: [
                    _TableHeader(showEquivalent: _showEquivalent),
                    const Divider(height: 1),
                    ..._buildRows(weeklyHours),
                    const Divider(height: 1),
                    _TotalRow(
                      monthHours: _monthHours,
                      monthEquivalent: _monthEquivalent,
                      weeklyHours: weeklyHours,
                      showEquivalent: _showEquivalent,
                    ),
                  ]),
                ),
              ),
              if (_showEquivalent)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Text(
                    'Äquivalent = Ist × Zuschlagsfaktor (Sa 1.5×, So/Feiertag 2×) – '
                    'nur für Sonderarbeitszeiten ohne Homeoffice. '
                    'Zeigt den vertraglichen Gegenwert der geleisteten Arbeit.',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                ),
              const SizedBox(height: 12),
              // ── Abwesenheitsübersicht ────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Abwesenheiten ${_fyLabel}',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _AbsenceRow(
                        icon: Icons.beach_access_outlined,
                        label: 'Urlaub',
                        days: _vacationDays,
                        total: employer?.vacationDaysPerYear ?? 25,
                        color: Colors.blue.shade600,
                      ),
                      if (_sickDays > 0)
                        _AbsenceRow(
                          icon: Icons.sick_outlined,
                          label: 'Krankenstand',
                          days: _sickDays,
                          color: Colors.orange.shade700,
                        ),
                      if (_compensatoryDays > 0)
                        _AbsenceRow(
                          icon: Icons.event_available_outlined,
                          label: 'Zeitausgleich',
                          days: _compensatoryDays,
                          color: Colors.green.shade700,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Legende ──────────────────────────────────────────────
              _Legend(),
            ],
          );
  }

  List<Widget> _buildRows(double weeklyHours) {
    final rows = <Widget>[];
    double cumDiff = 0;
    final mf = DateFormat('MMM', 'de_AT');

    for (var i = 0; i < 12; i++) {
      final monthDate =
          DateTime(_fyStart.year, _fyStart.month + i);
      final soll = weeklyHours * 4.33;
      final ist = _monthHours[i];
      final diff = ist - soll;
      cumDiff += diff;

      final isFuture = monthDate.isAfter(DateTime.now());

      rows.add(_MonthRow(
        label: mf.format(monthDate),
        soll: soll,
        ist: ist,
        equivalent: _monthEquivalent[i],
        showEquivalent: _showEquivalent,
        diff: diff,
        cumDiff: cumDiff,
        isFuture: isFuture,
      ));
    }
    return rows;
  }
}

class _TableHeader extends StatelessWidget {
  final bool showEquivalent;
  const _TableHeader({this.showEquivalent = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SizedBox(width: 40, child: Text('Monat', style: style)),
        Expanded(child: Text('Soll', style: style, textAlign: TextAlign.right)),
        Expanded(child: Text('Ist', style: style, textAlign: TextAlign.right)),
        if (showEquivalent)
          Expanded(
              child: Text('Äquiv.', style: style, textAlign: TextAlign.right)),
        Expanded(child: Text('Diff', style: style, textAlign: TextAlign.right)),
        Expanded(
            child: Text('Kumuliert', style: style, textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String label;
  final double soll;
  final double ist;
  final double equivalent;
  final bool showEquivalent;
  final double diff;
  final double cumDiff;
  final bool isFuture;

  const _MonthRow({
    required this.label,
    required this.soll,
    required this.ist,
    this.equivalent = 0,
    this.showEquivalent = false,
    required this.diff,
    required this.cumDiff,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isFuture
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.35)
        : null;
    final diffColor = isFuture
        ? textColor
        : diff > 0.25
            ? Colors.orange.shade700
            : diff < -0.25
                ? Colors.red.shade400
                : Colors.green.shade600;
    final cumColor = isFuture
        ? textColor
        : cumDiff > 0.25
            ? Colors.orange.shade700
            : cumDiff < -0.25
                ? Colors.red.shade400
                : Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        SizedBox(
            width: 40,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor))),
        Expanded(
            child: Text(_fmtH(soll),
                style: TextStyle(fontSize: 12, color: textColor),
                textAlign: TextAlign.right)),
        Expanded(
            child: Text(ist > 0 || !isFuture ? _fmtH(ist) : '–',
                style: TextStyle(fontSize: 12, color: textColor),
                textAlign: TextAlign.right)),
        if (showEquivalent)
          Expanded(
              child: Text(
                  equivalent > 0 || !isFuture ? _fmtH(equivalent) : '–',
                  style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: equivalent > ist + 0.01
                          ? FontWeight.w600
                          : FontWeight.normal),
                  textAlign: TextAlign.right)),
        Expanded(
            child: Text(
                isFuture ? '–' : '${diff >= 0 ? '+' : ''}${_fmtH(diff)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: diffColor),
                textAlign: TextAlign.right)),
        Expanded(
            child: Text(
                isFuture ? '–' : '${cumDiff >= 0 ? '+' : ''}${_fmtH(cumDiff)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cumColor),
                textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final List<double> monthHours;
  final List<double> monthEquivalent;
  final double weeklyHours;
  final bool showEquivalent;

  const _TotalRow({
    required this.monthHours,
    this.monthEquivalent = const [],
    required this.weeklyHours,
    this.showEquivalent = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalSoll = weeklyHours * 4.33 * 12;
    final totalIst = monthHours.fold(0.0, (s, h) => s + h);
    final totalEq  = monthEquivalent.fold(0.0, (s, h) => s + h);
    final diff = totalIst - totalSoll;
    final diffColor = diff > 0.25
        ? Colors.orange.shade700
        : diff < -0.25
            ? Colors.red.shade400
            : Colors.green.shade600;

    final style =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        const SizedBox(
            width: 40,
            child: Text('Ges.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        Expanded(
            child: Text(_fmtH(totalSoll),
                style: style, textAlign: TextAlign.right)),
        Expanded(
            child: Text(_fmtH(totalIst),
                style: style, textAlign: TextAlign.right)),
        if (showEquivalent)
          Expanded(
              child: Text(_fmtH(totalEq),
                  style: style.copyWith(
                      color: totalEq > totalIst + 0.01
                          ? Colors.amber.shade800
                          : null),
                  textAlign: TextAlign.right)),
        Expanded(
            child: Text('${diff >= 0 ? '+' : ''}${_fmtH(diff)}',
                style: style.copyWith(color: diffColor),
                textAlign: TextAlign.right)),
        const Expanded(child: SizedBox()),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _LegendItem(color: Colors.green.shade600, label: 'Ausgeglichen'),
          _LegendItem(color: Colors.orange.shade700, label: 'Mehrarbeit'),
          _LegendItem(color: Colors.red.shade400, label: 'Minderstunden'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }
}

class _AbsenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int days;
  final int? total;
  final Color color;

  const _AbsenceRow({
    required this.icon,
    required this.label,
    required this.days,
    this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total != null ? total! - days : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              if (total != null) ...[
                Text('$days / $total Tage',
                    style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: (days / total!).clamp(0.0, 1.0),
                    color: color,
                    backgroundColor: color.withOpacity(0.15),
                  ),
                ),
              ] else
                Text('$days Tage',
                    style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                remaining >= 0
                    ? 'Resturlaub: $remaining Tage'
                    : 'Überzogen: ${-remaining} Tage',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining >= 0
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      : Colors.red.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Gemeinsame Hilfswidgets ───────────────────────────────────────────────────

String _fmtH(double h) {
  final neg = h < 0;
  final abs = h.abs();
  final hh = abs.floor();
  final mm = ((abs - hh) * 60).round();
  return '${neg ? '-' : ''}${hh}h ${mm.toString().padLeft(2, '0')}m';
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon),
        title: Text(title),
        subtitle:
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: loading ? null : onTap,
      ),
    );
  }
}
