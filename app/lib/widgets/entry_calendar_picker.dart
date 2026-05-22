import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';

/// Day-level metadata loaded from the database.
class _DayMeta {
  final bool hasVacation;
  final bool hasSick;
  final bool hasZA;
  final bool hasOther;
  const _DayMeta({
    this.hasVacation = false,
    this.hasSick = false,
    this.hasZA = false,
    this.hasOther = false,
  });
}

/// Custom date picker dialog that decorates calendar cells with entry indicators:
///   U  = Urlaubstag       (blue)
///   K  = Krankenstandstag (orange)
///   ZA = Zeitausgleich    (green)
///   ●  = sonstiger Eintrag (grey dot)
class EntryCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const EntryCalendarPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  /// Show as a dialog. Returns the selected [DateTime] or null if cancelled.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: EntryCalendarPicker(
          initialDate: initialDate,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030),
        ),
      ),
    );
  }

  @override
  State<EntryCalendarPicker> createState() => _EntryCalendarPickerState();
}

class _EntryCalendarPickerState extends State<EntryCalendarPicker> {
  late DateTime _displayMonth; // always day=1
  late DateTime _selected;
  Map<DateTime, _DayMeta> _meta = {};
  bool _loading = false;
  int _loadGen = 0; // incremented per load; guards against stale async results

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _displayMonth = DateTime(_selected.year, _selected.month);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    if (!mounted) return;
    final gen = ++_loadGen;
    setState(() => _loading = true);
    final from = _displayMonth;
    final to =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0); // last day
    final entries =
        await DatabaseHelper.instance.getEntriesForDateRange(from, to);

    final map = <DateTime, _DayMeta>{};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      final cur = map[key];
      map[key] = _DayMeta(
        hasVacation: (cur?.hasVacation ?? false) ||
            e.workType == WorkType.vacation,
        hasSick:
            (cur?.hasSick ?? false) || e.workType == WorkType.sick,
        hasZA: (cur?.hasZA ?? false) ||
            e.workType == WorkType.compensatoryLeave,
        hasOther: (cur?.hasOther ?? false) ||
            (e.workType != WorkType.vacation &&
                e.workType != WorkType.sick &&
                e.workType != WorkType.compensatoryLeave),
      );
    }
    // Only apply if this is still the latest request (guard stale results).
    if (mounted && gen == _loadGen) {
      setState(() { _meta = map; _loading = false; });
    }
  }

  void _navigate(int delta) {
    final next =
        DateTime(_displayMonth.year, _displayMonth.month + delta);
    final minMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    final maxMonth =
        DateTime(widget.lastDate.year, widget.lastDate.month);
    if (next.isBefore(minMonth) || next.isAfter(maxMonth)) return;
    setState(() => _displayMonth = next);
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mf = DateFormat('MMMM yyyy', 'de_AT');
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    // weekday 1=Mon … 7=Sun → column offset (0=Mon)
    final startOffset = (_displayMonth.weekday - 1) % 7;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Month navigation ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _navigate(-1),
                ),
                Text(mf.format(_displayMonth),
                    style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _navigate(1),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // ── Weekday headers ───────────────────────────────────────
            Row(
              children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 2),
            // ── Day grid ──────────────────────────────────────────────
            _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _buildGrid(daysInMonth, startOffset, todayKey, theme),
            const SizedBox(height: 8),
            // ── Legend ────────────────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                _LegendChip('U', Colors.blue.shade700, 'Urlaub'),
                _LegendChip('K', Colors.orange.shade700, 'Krankenstand'),
                _LegendChip('ZA', Colors.green.shade700, 'Zeitausgleich'),
                _LegendChip('●', theme.colorScheme.onSurface.withOpacity(0.4),
                    'Eintrag vorhanden'),
              ],
            ),
            // ── Cancel ────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
      int daysInMonth, int startOffset, DateTime todayKey, ThemeData theme) {
    final cells = <Widget>[
      // Leading empty cells
      for (var i = 0; i < startOffset; i++) const SizedBox(),
      // Day cells
      for (var day = 1; day <= daysInMonth; day++)
        _buildDayCell(day, todayKey, theme),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      childAspectRatio: 0.85,
      children: cells,
    );
  }

  Widget _buildDayCell(int day, DateTime todayKey, ThemeData theme) {
    final date = DateTime(_displayMonth.year, _displayMonth.month, day);
    final isSelected = date.year == _selected.year &&
        date.month == _selected.month &&
        date.day == _selected.day;
    final isToday = date == todayKey;
    final isWeekend = date.weekday == 6 ||
        date.weekday == 7 ||
        HolidayService.instance.isHoliday(date);
    final isOutOfRange =
        date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);
    final meta = _meta[date];
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: isOutOfRange ? null : () => Navigator.pop(context, date),
      child: _DayCell(
        day: day,
        isSelected: isSelected,
        isToday: isToday,
        isWeekend: isWeekend,
        isOutOfRange: isOutOfRange,
        meta: meta,
        cs: cs,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final bool isOutOfRange;
  final _DayMeta? meta;
  final ColorScheme cs;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    required this.isOutOfRange,
    required this.cs,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    // ── Colours ─────────────────────────────────────────────────────
    Color numColor;
    FontWeight numWeight = FontWeight.normal;
    BoxDecoration? deco;

    if (isSelected) {
      deco = BoxDecoration(color: cs.primary, shape: BoxShape.circle);
      numColor = cs.onPrimary;
      numWeight = FontWeight.bold;
    } else if (isToday) {
      deco = BoxDecoration(
        border: Border.all(color: cs.primary, width: 1.5),
        shape: BoxShape.circle,
      );
      numColor = cs.primary;
      numWeight = FontWeight.w600;
    } else if (isOutOfRange) {
      numColor = cs.onSurface.withOpacity(0.2);
    } else if (isWeekend) {
      numColor = cs.onSurface.withOpacity(0.45);
    } else {
      numColor = cs.onSurface;
    }

    // ── Indicator label ──────────────────────────────────────────────
    String? indicator;
    Color indicatorColor = cs.onSurface.withOpacity(0.4);
    if (!isSelected && meta != null) {
      if (meta!.hasVacation) {
        indicator = 'U';
        indicatorColor = Colors.blue.shade700;
      } else if (meta!.hasSick) {
        indicator = 'K';
        indicatorColor = Colors.orange.shade700;
      } else if (meta!.hasZA) {
        indicator = 'ZA';
        indicatorColor = Colors.green.shade700;
      } else if (meta!.hasOther) {
        indicator = '●';
      }
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: deco,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day',
              style: TextStyle(
                  fontSize: 13, fontWeight: numWeight, color: numColor)),
          if (indicator != null)
            Text(indicator,
                style: TextStyle(
                    fontSize: indicator == '●' ? 9 : 8,
                    fontWeight: FontWeight.bold,
                    color: indicatorColor,
                    height: 1.1)),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String symbol;
  final Color color;
  final String label;
  const _LegendChip(this.symbol, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    final dimColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(symbol,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      Text(' = $label',
          style: TextStyle(fontSize: 10, color: dimColor)),
    ]);
  }
}
