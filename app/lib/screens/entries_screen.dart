import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_entry_provider.dart';
import '../providers/employer_provider.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';
import 'entry_form_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});
  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TimeEntryProvider>();
    final employer = context.watch<EmployerProvider>().active;
    final weeklyTarget = employer?.weeklyHours ?? 40.0;
    final byWeek = tp.entriesByWeek;
    final sortedWeeks = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));
    final df = DateFormat('MMMM yyyy', 'de_AT');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(df.format(DateTime(tp.selectedYear, tp.selectedMonth))),
            if (employer != null)
              Text(employer.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final prev = DateTime(tp.selectedYear, tp.selectedMonth - 1);
              tp.loadMonth(prev.year, prev.month);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final next = DateTime(tp.selectedYear, tp.selectedMonth + 1);
              tp.loadMonth(next.year, next.month);
            },
          ),
        ],
      ),
      body: byWeek.isEmpty
          ? Center(
              child: Text(employer != null
                  ? 'Keine Einträge für ${employer.name}'
                  : 'Keine Einträge in diesem Monat'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: sortedWeeks.length,
              itemBuilder: (context, i) {
                final weekKey = sortedWeeks[i];
                final monday = DateTime.parse(weekKey);
                final sunday = monday.add(const Duration(days: 6));
                final entries = byWeek[weekKey]!;
                entries.sort((a, b) => b.startTime.compareTo(a.startTime));
                final weekHours = entries.fold(0.0, (s, e) => s + e.totalHours);
                final hh = weekHours.floor();
                final mm = ((weekHours - hh) * 60).round();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: i == 0,
                    title: Text(
                      'KW ${_kw(monday)}: ${DateFormat('d.M.', 'de_AT').format(monday)}–${DateFormat('d.M.', 'de_AT').format(sunday)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WeekChip(hours: weekHours, target: weeklyTarget),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    children: [
                      ...entries.map((e) => _EntryRow(
                        entry: e,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryFormScreen(entry: e))),
                        onDelete: () => _confirmDelete(context, e),
                      )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Gesamt: ${hh}h ${mm.toString().padLeft(2, '0')}m',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _kw(DateTime monday) {
    final jan4 = DateTime(monday.year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    return ((monday.difference(startOfWeek1).inDays) ~/ 7) + 1;
  }

  Future<void> _confirmDelete(BuildContext context, TimeEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Dieser Eintrag wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TimeEntryProvider>().deleteEntry(e.id);
    }
  }
}

class _WeekChip extends StatelessWidget {
  final double hours;
  final double target;
  const _WeekChip({required this.hours, required this.target});

  @override
  Widget build(BuildContext context) {
    final hh = hours.floor();
    final mm = ((hours - hh) * 60).round();
    final over = hours > target;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: over ? Colors.orange.shade100 : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${hh}h ${mm.toString().padLeft(2, '0')}m',
        style: TextStyle(fontSize: 12, color: over ? Colors.orange.shade800 : null, fontWeight: FontWeight.w500)),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final TimeEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _EntryRow({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('HH:mm');
    final df = DateFormat('EE d.M.', 'de_AT');
    final hh = entry.totalHours.floor();
    final mm = ((entry.totalHours - hh) * 60).round();
    final rowColor = _rowColor(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        color: rowColor,
        child: ListTile(
          leading: Icon(_icon(entry.workType), color: _iconColor(context)),
          title: _buildTitle(df, tf),
          subtitle: _buildSubtitle(context),
          trailing: entry.workType.isAbsence
              ? Chip(
                  label: Text(entry.workType.label,
                      style: const TextStyle(fontSize: 11)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: _absenceChipColor(context),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${hh}h ${mm.toString().padLeft(2, '0')}m',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (entry.distanceKm != null && entry.distanceKm! > 0)
                      Text('${entry.distanceKm!.toStringAsFixed(0)} km',
                          style: const TextStyle(fontSize: 11)),
                    if (entry.travelMinutes > 0)
                      Text('${entry.travelMinutes} min Fahrt',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildTitle(DateFormat df, DateFormat tf) {
    final dateStr = df.format(entry.date);
    if (entry.workType.isAbsence) {
      return Text(dateStr);
    }
    final startStr = tf.format(entry.startTime);
    final endStr = entry.endTime != null ? tf.format(entry.endTime!) : '...';
    return Text('$dateStr $startStr–$endStr');
  }

  Widget _buildSubtitle(BuildContext context) {
    final holidayName = HolidayService.instance.holidayName(entry.date);
    final chips = <Widget>[];
    if (entry.dayType != DayType.workday) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(entry.dayType.label, style: const TextStyle(fontSize: 10)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ));
    }
    final texts = <String>[];
    if (holidayName != null) texts.add(holidayName);
    if (entry.note.isNotEmpty) texts.add(entry.note);
    final subtitle = texts.join(' · ');
    if (chips.isEmpty && subtitle.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        ...chips,
        if (subtitle.isNotEmpty)
          Expanded(
            child: Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Color? _rowColor(BuildContext context) {
    if (entry.workType.isAbsence) {
      return switch (entry.workType) {
        WorkType.vacation => Colors.blue.shade50,
        WorkType.sick => Colors.orange.shade50,
        WorkType.compensatoryLeave => Colors.green.shade50,
        _ => null,
      };
    }
    return switch (entry.dayType) {
      DayType.holiday => Colors.red.shade50,
      DayType.sunday => Colors.orange.shade50,
      DayType.saturday => Colors.amber.shade50,
      DayType.workday => null,
    };
  }

  Color? _iconColor(BuildContext context) {
    return switch (entry.workType) {
      WorkType.vacation => Colors.blue.shade600,
      WorkType.sick => Colors.orange.shade700,
      WorkType.compensatoryLeave => Colors.green.shade700,
      _ => null,
    };
  }

  Color? _absenceChipColor(BuildContext context) {
    return switch (entry.workType) {
      WorkType.vacation => Colors.blue.shade100,
      WorkType.sick => Colors.orange.shade100,
      WorkType.compensatoryLeave => Colors.green.shade100,
      _ => null,
    };
  }

  IconData _icon(WorkType t) => switch (t) {
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
