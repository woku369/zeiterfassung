import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../models/entry_project_split.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  // ── Colours ──────────────────────────────────────────────────────────────────
  static final _blue     = ExcelColor.fromHexString('#1565C0');
  static final _white    = ExcelColor.fromHexString('#FFFFFF');
  static final _blueLight= ExcelColor.fromHexString('#E3F2FD');
  static final _grey     = ExcelColor.fromHexString('#F5F5F5');
  static final _orange   = ExcelColor.fromHexString('#FFF3E0');
  static final _green    = ExcelColor.fromHexString('#E8F5E9');
  static final _red      = ExcelColor.fromHexString('#FFEBEE');
  static final _title      = ExcelColor.fromHexString('#0D47A1');
  static final _surcharge50  = ExcelColor.fromHexString('#FFF8E1'); // amber-50
  static final _surcharge100 = ExcelColor.fromHexString('#FCE4EC'); // pink-50
  static final _argBg        = ExcelColor.fromHexString('#EDE7F6'); // deep-purple-50
  static final _argHeader    = ExcelColor.fromHexString('#4527A0'); // deep-purple-900

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Monthly XLSX — Monat mit Kopfzeile, KW-Summen, Monatssumme.
  Future<File> exportMonth({
    required List<TimeEntry> entries,
    required int year,
    required int month,
    String employerName = '',
    double weeklyHours = 40,
    Map<String, List<EntryProjectSplit>> splits = const {},
    Map<String, String> projectNames = const {},
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Zeiterfassung');
    final sheet = excel['Zeiterfassung'];

    final periodLabel = DateFormat('MMMM yyyy', 'de_AT').format(DateTime(year, month));
    final monthTotal  = entries.fold(0.0, (s, e) => s + e.totalHours);
    final monthSoll   = weeklyHours * 4.33;
    final diff        = monthTotal - monthSoll;
    final infoLine    = 'Wochensoll: ${_fmtH(weeklyHours)}  ·  '
                        'Monatssoll: ${_fmtH(monthSoll)}  ·  '
                        'Ist: ${_fmtH(monthTotal)}  ·  '
                        'Differenz: ${diff >= 0 ? '+' : ''}${_fmtH(diff)}';

    var row = 0;
    _writeTitleRow(sheet, row++, 'ZEITERFASSUNG  –  ${employerName.toUpperCase()}');
    _writeInfoRow(sheet, row++, periodLabel, infoLine);
    row++; // blank separator
    _writeDetailHeaders(sheet, row++);
    row = _writeDetailRows(sheet, row, entries, weeklyHours,
        splits: splits, projectNames: projectNames);
    row = _writeProjectSummary(sheet, row + 1, entries, splits, projectNames);

    _setDetailColumnWidths(sheet);
    return _save(excel, employerName, DateFormat('yyyy-MM').format(DateTime(year, month)));
  }

  /// Fiscal-year XLSX — Zusammenfassung + Detaildaten.
  Future<File> exportYear({
    required List<TimeEntry> allEntries,
    required DateTime fyStart,
    String employerName = '',
    double weeklyHours = 40,
    bool isSurchargeEmployer = false,
    Map<String, List<EntryProjectSplit>> splits = const {},
    Map<String, String> projectNames = const {},
  }) async {
    final excel    = Excel.createExcel();
    excel.rename('Sheet1', 'Jahresübersicht');
    final summary  = excel['Jahresübersicht'];
    final detail   = excel['Details'];

    final fyEnd    = DateTime(fyStart.year + 1, fyStart.month);
    final endYear  = (fyStart.year + 1) % 100;
    final fyLabel  = 'WJ ${fyStart.year}/${endYear.toString().padLeft(2, '0')}';

    // ── Zusammenfassungsblatt ─────────────────────────────────────────────────
    var row = 0;
    _writeTitleRow(summary, row++, 'JAHRESBERICHT $fyLabel  –  ${employerName.toUpperCase()}');
    row++; // blank

    // Summary headers
    final sumHeaders = ['Monat', 'Soll (h)', 'Ist (h)', 'Differenz', 'Kumuliert',
                        'Urlaub', 'Krankenstand', 'ZA'];
    for (var c = 0; c < sumHeaders.length; c++) {
      final cell = summary.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(sumHeaders[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blue, fontColorHex: _white);
    }
    row++;

    double cumDiff   = 0;
    double totalIst  = 0;
    double totalSoll = 0;
    int totalVac = 0, totalSick = 0, totalZa = 0;

    for (var i = 0; i < 12; i++) {
      final mDate   = DateTime(fyStart.year, fyStart.month + i);
      final mSoll   = weeklyHours * 4.33;
      final mIst    = allEntries
          .where((e) => e.date.year == mDate.year && e.date.month == mDate.month
              && !e.workType.isAbsence)
          .fold(0.0, (s, e) => s + e.totalHours);
      final mVac    = allEntries.where((e) => e.date.year == mDate.year
          && e.date.month == mDate.month && e.workType == WorkType.vacation).length;
      final mSick   = allEntries.where((e) => e.date.year == mDate.year
          && e.date.month == mDate.month && e.workType == WorkType.sick).length;
      final mZa     = allEntries.where((e) => e.date.year == mDate.year
          && e.date.month == mDate.month && e.workType == WorkType.compensatoryLeave).length;
      final diff    = mIst - mSoll;
      cumDiff      += diff;
      totalIst     += mIst;
      totalSoll    += mSoll;
      totalVac     += mVac;
      totalSick    += mSick;
      totalZa      += mZa;

      final isFuture = mDate.isAfter(DateTime.now());
      final bg = isFuture ? _grey : (diff >= 0.5 ? _green : diff < -0.5 ? _red : _white);

      _setSummaryRow(summary, row++, [
        TextCellValue(DateFormat('MMM yyyy', 'de_AT').format(mDate)),
        TextCellValue(_fmtH(mSoll)),
        TextCellValue(isFuture ? '' : _fmtH(mIst)),
        TextCellValue(isFuture ? '' : '${diff >= 0 ? '+' : ''}${_fmtH(diff)}'),
        TextCellValue(isFuture ? '' : '${cumDiff >= 0 ? '+' : ''}${_fmtH(cumDiff)}'),
        IntCellValue(mVac),
        IntCellValue(mSick),
        IntCellValue(mZa),
      ], bg);
    }

    // Total row
    final totalDiff = totalIst - totalSoll;
    _setSummaryRow(summary, row++, [
      TextCellValue('Jahressumme'),
      TextCellValue(_fmtH(totalSoll)),
      TextCellValue(_fmtH(totalIst)),
      TextCellValue('${totalDiff >= 0 ? '+' : ''}${_fmtH(totalDiff)}'),
      TextCellValue('${totalDiff >= 0 ? '+' : ''}${_fmtH(totalDiff)}'),
      IntCellValue(totalVac),
      IntCellValue(totalSick),
      IntCellValue(totalZa),
    ], _blueLight, bold: true);

    summary.setColumnWidth(0, 16);
    for (var c = 1; c < 8; c++) summary.setColumnWidth(c, 12);

    // ── Detailblatt ───────────────────────────────────────────────────────────
    var dRow = 0;
    _writeTitleRow(detail, dRow++, 'DETAILS $fyLabel  –  ${employerName.toUpperCase()}');
    dRow++; // blank
    _writeDetailHeaders(detail, dRow++);

    final workEntries = List<TimeEntry>.from(
        allEntries.where((e) => !e.workType.isAbsence || true))
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Group by month, insert month-header rows between months
    int? curMonth;
    for (final e in workEntries) {
      if (curMonth != e.date.month || (dRow > 4 && curMonth != e.date.month)) {
        if (curMonth != null) {
          // KW-Summe for previous section is handled inside _writeDetailRows,
          // here we just insert a month-label separator.
          final mLabel = DateFormat('MMMM yyyy', 'de_AT').format(e.date);
          final sep = detail.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dRow));
          sep.value = TextCellValue(mLabel);
          sep.cellStyle = CellStyle(bold: true, backgroundColorHex: _blueLight);
          dRow++;
        }
        curMonth = e.date.month;
      }
    }
    // Re-do: write all entries in one pass (simpler, no month separators needed –
    // the date column makes it clear).
    dRow = 3; // reset to after headers
    final endDetailRow = _writeDetailRows(detail, dRow, workEntries, weeklyHours,
        splits: splits, projectNames: projectNames);
    _writeProjectSummary(detail, endDetailRow + 1, workEntries, splits, projectNames);
    _setDetailColumnWidths(detail);

    if (isSurchargeEmployer) {
      _buildSurchargeSheet(excel, fyLabel, employerName, allEntries, weeklyHours);
    }

    return _save(excel, employerName, fyLabel.replaceAll('/', '-'));
  }

  /// Custom date range XLSX.
  Future<File> exportRange({
    required List<TimeEntry> entries,
    required DateTime from,
    required DateTime to,
    String employerName = '',
    double weeklyHours = 40,
    Map<String, List<EntryProjectSplit>> splits = const {},
    Map<String, String> projectNames = const {},
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Zeiterfassung');
    final sheet = excel['Zeiterfassung'];

    final df = DateFormat('dd.MM.yyyy');
    final periodLabel = '${df.format(from)} – ${df.format(to)}';
    final rangeTotal  = entries.fold(0.0, (s, e) => s + e.totalHours);
    final days        = to.difference(from).inDays + 1;
    final rangeSoll   = weeklyHours / 5 * (days * 5 / 7); // rough working days
    final diff        = rangeTotal - rangeSoll;
    final infoLine    = 'Zeitraum: $periodLabel  ·  '
                        'Ist: ${_fmtH(rangeTotal)}  ·  '
                        'Differenz (Schätzung): ${diff >= 0 ? '+' : ''}${_fmtH(diff)}';

    var row = 0;
    _writeTitleRow(sheet, row++, 'ZEITERFASSUNG  –  ${employerName.toUpperCase()}');
    _writeInfoRow(sheet, row++, periodLabel, infoLine);
    row++; // blank
    _writeDetailHeaders(sheet, row++);
    row = _writeDetailRows(sheet, row, entries, weeklyHours,
        splits: splits, projectNames: projectNames);
    _writeProjectSummary(sheet, row + 1, entries, splits, projectNames);

    _setDetailColumnWidths(sheet);
    return _save(excel, employerName,
        '${df.format(from).replaceAll('.', '-')}_bis_${df.format(to).replaceAll('.', '-')}');
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  void _writeTitleRow(Sheet sheet, int row, String text) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 13,
      backgroundColorHex: _title,
      fontColorHex: _white,
    );
    // Blank the other columns with same bg (12 covers Zuschläge sheet width)
    for (var c = 1; c < 12; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = CellStyle(backgroundColorHex: _title);
    }
  }

  void _writeInfoRow(Sheet sheet, int row, String label, String info) {
    final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    c0.value = TextCellValue(label);
    c0.cellStyle = CellStyle(bold: true, backgroundColorHex: _blueLight);

    final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    c1.value = TextCellValue(info);
    c1.cellStyle = CellStyle(backgroundColorHex: _blueLight);

    for (var c = 2; c < 10; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = CellStyle(backgroundColorHex: _blueLight);
    }
  }

  void _writeDetailHeaders(Sheet sheet, int row) {
    final headers = ['Datum', 'Wochentag', 'Beginn', 'Ende', 'Pause (min)',
                     'Netto (h)', 'Tätigkeit', 'Tagtyp', 'Notiz', 'km', 'Projekte'];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blue, fontColorHex: _white);
    }
  }

  /// Formats project assignment for one entry as "Projekt1 30m, Projekt2 60m"
  /// (or just names if no explicit split minutes). Falls back to legacy
  /// entry.projectId if no splits exist.
  String _formatProjects(
    TimeEntry entry,
    Map<String, List<EntryProjectSplit>> splits,
    Map<String, String> projectNames,
  ) {
    final s = splits[entry.id];
    if (s != null && s.isNotEmpty) {
      return s.map((sp) {
        final name = projectNames[sp.projectId] ?? '?';
        return sp.minutes > 0 ? '$name ${sp.minutes}m' : name;
      }).join(', ');
    }
    if (entry.projectId != null) {
      return projectNames[entry.projectId!] ?? '';
    }
    return '';
  }

  /// Writes entries with KW-Summen. Returns next free row index.
  int _writeDetailRows(Sheet sheet, int startRow, List<TimeEntry> entries, double weeklyHours,
      {Map<String, List<EntryProjectSplit>> splits = const {},
       Map<String, String> projectNames = const {}}) {
    final df  = DateFormat('dd.MM.yyyy');
    final tf  = DateFormat('HH:mm');
    final wdf = DateFormat('EEEE', 'de_AT');

    final sorted = List<TimeEntry>.from(entries)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    var row = startRow;
    double weekTotal = 0;
    double monthTotal = 0;
    double totalKm = 0;
    DateTime? currentWeekMonday;
    int? currentMonth;

    for (final entry in sorted) {
      final monday    = entry.date.subtract(Duration(days: entry.date.weekday - 1));
      final mondayKey = monday.toIso8601String().substring(0, 10);
      final prevKey   = currentWeekMonday?.toIso8601String().substring(0, 10);

      // KW-Summe wenn Woche wechselt
      if (prevKey != null && prevKey != mondayKey && weekTotal > 0) {
        _addSubtotalRow(sheet, row++, weekTotal, 'KW-Summe');
        weekTotal = 0;
      }
      currentWeekMonday = monday;
      currentMonth ??= entry.date.month;

      final isWeekend = entry.dayType == DayType.saturday ||
          entry.dayType == DayType.sunday ||
          entry.dayType == DayType.holiday;
      final isAbsence = entry.workType.isAbsence;

      final cells = [
        TextCellValue(df.format(entry.date)),
        TextCellValue(wdf.format(entry.date)),
        TextCellValue(tf.format(entry.startTime)),
        TextCellValue(entry.endTime != null ? tf.format(entry.endTime!) : ''),
        isAbsence ? TextCellValue('') : IntCellValue(entry.breakMinutes),
        isAbsence ? TextCellValue(entry.workType.label)
                  : DoubleCellValue(double.parse(entry.totalHours.toStringAsFixed(2))),
        isAbsence ? TextCellValue('') : TextCellValue(entry.workType.label),
        TextCellValue(entry.dayType.label),
        TextCellValue(entry.note),
        entry.distanceKm != null && entry.distanceKm! > 0
            ? DoubleCellValue(entry.distanceKm!)
            : TextCellValue(''),
        TextCellValue(_formatProjects(entry, splits, projectNames)),
      ];

      ExcelColor? bg;
      if (isAbsence)      bg = _green;
      else if (isWeekend) bg = _orange;

      for (var c = 0; c < cells.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        cell.value = cells[c];
        if (bg != null) cell.cellStyle = CellStyle(backgroundColorHex: bg);
      }

      if (!isAbsence) weekTotal += entry.totalHours;
      monthTotal += entry.totalHours;
      totalKm    += entry.distanceKm ?? 0;
      row++;
    }

    if (weekTotal > 0) _addSubtotalRow(sheet, row++, weekTotal, 'KW-Summe');
    _addSubtotalRow(sheet, row++, monthTotal, 'Summe',
        bold: true, km: totalKm > 0 ? totalKm : null);

    return row;
  }

  void _addSubtotalRow(Sheet sheet, int row, double hours, String label,
      {bool bold = false, double? km}) {
    final values = [label, '', '', '', '',
        TextCellValue(_fmtH(hours)), '', '', '', '', ''];
    for (var c = 0; c < 11; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      final v = values[c];
      cell.value = v is String ? TextCellValue(v) : v as CellValue;
      if (c == 9 && km != null) cell.value = DoubleCellValue(km);
      cell.cellStyle = CellStyle(
        bold: bold,
        backgroundColorHex: bold ? _blueLight : _grey,
      );
    }
  }

  void _setSummaryRow(Sheet sheet, int row, List<CellValue> values, ExcelColor bg,
      {bool bold = false}) {
    for (var c = 0; c < values.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = values[c];
      cell.cellStyle = CellStyle(bold: bold, backgroundColorHex: bg);
    }
  }

  void _setDetailColumnWidths(Sheet sheet) {
    sheet.setColumnWidth(0, 12); // Datum
    sheet.setColumnWidth(1, 14); // Wochentag
    sheet.setColumnWidth(2,  8); // Beginn
    sheet.setColumnWidth(3,  8); // Ende
    sheet.setColumnWidth(4, 10); // Pause
    sheet.setColumnWidth(5, 10); // Netto
    sheet.setColumnWidth(6, 14); // Tätigkeit
    sheet.setColumnWidth(7, 12); // Tagtyp
    sheet.setColumnWidth(8, 35); // Notiz
    sheet.setColumnWidth(9,  8); // km
    sheet.setColumnWidth(10, 30); // Projekte
  }

  /// Writes a project-time summary block. Returns next free row.
  /// Aggregates minutes per project across all entries; entries without an
  /// explicit split fall back to their legacy projectId (using entry.totalHours).
  int _writeProjectSummary(
    Sheet sheet,
    int startRow,
    List<TimeEntry> entries,
    Map<String, List<EntryProjectSplit>> splits,
    Map<String, String> projectNames,
  ) {
    final byProject = <String, double>{};
    double unassigned = 0;
    for (final e in entries) {
      if (e.workType.isAbsence) continue;
      final s = splits[e.id];
      if (s != null && s.isNotEmpty) {
        final splitTotal = s.fold<double>(0, (sum, sp) => sum + sp.minutes) / 60.0;
        for (final sp in s) {
          byProject[sp.projectId] =
              (byProject[sp.projectId] ?? 0) + sp.minutes / 60.0;
        }
        unassigned += (e.totalHours - splitTotal).clamp(0, double.infinity);
      } else if (e.projectId != null) {
        byProject[e.projectId!] = (byProject[e.projectId!] ?? 0) + e.totalHours;
      } else {
        unassigned += e.totalHours;
      }
    }
    if (byProject.isEmpty && unassigned <= 0.001) return startRow;

    var row = startRow;
    // Section title
    final t = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    t.value = TextCellValue('PROJEKTZUORDNUNG');
    t.cellStyle = CellStyle(bold: true, backgroundColorHex: _title, fontColorHex: _white);
    for (var c = 1; c < 11; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = CellStyle(backgroundColorHex: _title);
    }
    row++;

    // Header row
    final hdrs = ['Projekt', 'Stunden'];
    for (var c = 0; c < hdrs.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(hdrs[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blue, fontColorHex: _white);
    }
    row++;

    final sortedKeys = byProject.keys.toList()
      ..sort((a, b) => (byProject[b]!).compareTo(byProject[a]!));
    for (final pid in sortedKeys) {
      final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      nameCell.value = TextCellValue(projectNames[pid] ?? '(gelöschtes Projekt)');
      nameCell.cellStyle = CellStyle(backgroundColorHex: _grey);
      final hCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      hCell.value = TextCellValue(_fmtH(byProject[pid]!));
      hCell.cellStyle = CellStyle(backgroundColorHex: _grey);
      row++;
    }
    if (unassigned > 0.001) {
      final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      nameCell.value = TextCellValue('(ohne Projektzuordnung)');
      nameCell.cellStyle = CellStyle(backgroundColorHex: _orange);
      final hCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      hCell.value = TextCellValue(_fmtH(unassigned));
      hCell.cellStyle = CellStyle(backgroundColorHex: _orange);
      row++;
    }
    return row;
  }

  // ── Zuschläge helpers ────────────────────────────────────────────────────────

  /// Splits a single [entry]'s hours into normal / +50% / +100% buckets.
  /// Saturday: before 13:00 = normal, 13–20h = +50%, after 20:00 = +100%.
  /// Sunday / holiday: all hours = +100%.
  /// Workday: before 20:00 = normal, after 20:00 = +100%.
  ({double normalH, double surcharge50H, double surcharge100H,
    double effectiveH, String typeLabel})
  _surchargeBreakdown(TimeEntry entry) {
    final end = entry.endTime;
    if (entry.workType.isAbsence || end == null) {
      return (normalH: 0, surcharge50H: 0, surcharge100H: 0,
              effectiveH: 0, typeLabel: '');
    }
    if (entry.workType == WorkType.homeoffice) {
      return (normalH: entry.totalHours, surcharge50H: 0, surcharge100H: 0,
              effectiveH: entry.totalHours, typeLabel: 'Homeoffice');
    }
    final start   = entry.startTime;
    final date    = entry.date;
    final rawMin  = end.difference(start).inMinutes.toDouble();
    if (rawMin <= 0) {
      return (normalH: 0, surcharge50H: 0, surcharge100H: 0,
              effectiveH: 0, typeLabel: 'Normal');
    }
    // Scale: paid hours / raw clock hours (accounts for break deduction & travel addition)
    final scale = entry.totalHours / (rawMin / 60.0);

    // Returns the overlap of [start,end] with the window [wS,wE] in scaled hours.
    double seg(DateTime wS, DateTime wE) {
      final s = start.isAfter(wS) ? start : wS;
      final e = end.isBefore(wE)  ? end   : wE;
      if (!s.isBefore(e)) return 0;
      return e.difference(s).inMinutes / 60.0 * scale;
    }

    final d0       = DateTime(date.year, date.month, date.day);
    final c13      = DateTime(date.year, date.month, date.day, 13);
    final c20      = DateTime(date.year, date.month, date.day, 20);
    final nextDay  = d0.add(const Duration(days: 1));

    double normalH, s50H, s100H;
    String typeLabel;

    switch (entry.dayType) {
      case DayType.saturday:
        normalH   = seg(d0, c13);
        s50H      = seg(c13, c20);
        s100H     = seg(c20, nextDay);
        typeLabel = s100H > 0.001
            ? 'Sa ×1.5/×2.0'
            : s50H > 0.001 ? 'Sa ×1.5 (ab 13h)' : 'Sa normal';
      case DayType.sunday:
        normalH = 0; s50H = 0; s100H = entry.totalHours;
        typeLabel = 'Sonntag ×2.0';
      case DayType.holiday:
        normalH = 0; s50H = 0; s100H = entry.totalHours;
        typeLabel = 'Feiertag ×2.0';
      case DayType.workday:
        normalH = seg(d0, c20); s50H = 0; s100H = seg(c20, nextDay);
        typeLabel = s100H > 0.001 ? 'Nacht ×2.0' : 'Normal';
    }
    final effectiveH = normalH + s50H * 1.5 + s100H * 2.0;
    return (normalH: normalH, surcharge50H: s50H, surcharge100H: s100H,
            effectiveH: effectiveH, typeLabel: typeLabel);
  }

  void _writeSurchargeSubtotal(
    Sheet sheet, int row, {
    required String label,
    required double normalH,
    required double s50H,
    required double s100H,
    required double effH,
    required double km,
    required double travelH,
    bool bold = false,
    bool grandTotal = false,
  }) {
    final bg = grandTotal ? _blueLight : _grey;
    for (var c = 0; c < 12; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = switch (c) {
        0  => TextCellValue(label),
        5  => TextCellValue(_fmtH(normalH)),
        7  => TextCellValue(_fmtH(s50H)),
        8  => TextCellValue(_fmtH(s100H)),
        9  => TextCellValue(_fmtH(effH)),
        10 => km     > 0.01 ? DoubleCellValue(km)          : TextCellValue(''),
        11 => travelH > 0.01 ? TextCellValue(_fmtH(travelH)) : TextCellValue(''),
        _  => TextCellValue(''),
      };
      cell.cellStyle = CellStyle(bold: bold, backgroundColorHex: bg);
    }
  }

  void _buildSurchargeSheet(
    Excel excel,
    String fyLabel,
    String employerName,
    List<TimeEntry> allEntries,
    double weeklyHours,
  ) {
    final sheet = excel['Zuschläge'];
    final df  = DateFormat('dd.MM.yyyy');
    final tf  = DateFormat('HH:mm');
    final wdf = DateFormat('EEEE', 'de_AT');

    final workEntries = allEntries
        .where((e) => !e.workType.isAbsence && e.endTime != null)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    var row = 0;
    _writeTitleRow(sheet, row++,
        'ZUSCHLÄGE $fyLabel  –  ${employerName.toUpperCase()}');
    row++; // blank

    // ── Column headers ──────────────────────────────────────────────────────
    const headers = [
      'Datum', 'Wochentag', 'Tätigkeitsart', 'Beginn', 'Ende',
      'Normal (h)', 'Zuschlagstyp', '+50% (h)', '+100% (h)', 'Effektiv (h)',
      'km', 'Fahrzeit (h)',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blue, fontColorHex: _white);
    }
    row++;

    // ── Data rows grouped by month ──────────────────────────────────────────
    double totNH = 0, totS50 = 0, totS100 = 0, totEff = 0, totKm = 0, totTH = 0;
    double mNH   = 0, mS50  = 0, mS100  = 0, mEff  = 0, mKm  = 0, mTH  = 0;
    int? curYM; // year*12+month to handle fiscal year spanning two calendar years

    for (final entry in workEntries) {
      final ym = entry.date.year * 12 + entry.date.month;

      if (ym != curYM) {
        // Monthly subtotal for the outgoing month
        if (curYM != null) {
          _writeSurchargeSubtotal(sheet, row++,
              label: 'Monatssumme', normalH: mNH, s50H: mS50, s100H: mS100,
              effH: mEff, km: mKm, travelH: mTH, bold: true);
          mNH = mS50 = mS100 = mEff = mKm = mTH = 0;
        }
        // Month header row
        final mLabel = DateFormat('MMMM yyyy', 'de_AT').format(entry.date);
        for (var c = 0; c < 12; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
          if (c == 0) cell.value = TextCellValue(mLabel);
          cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blueLight);
        }
        row++;
        curYM = ym;
      }

      final bd      = _surchargeBreakdown(entry);
      final km      = entry.distanceKm ?? 0;
      final travelH = entry.travelMinutes / 60.0;

      mNH   += bd.normalH;      mS50  += bd.surcharge50H;
      mS100 += bd.surcharge100H; mEff  += bd.effectiveH;
      mKm   += km;               mTH   += travelH;
      totNH  += bd.normalH;     totS50 += bd.surcharge50H;
      totS100 += bd.surcharge100H; totEff += bd.effectiveH;
      totKm  += km;             totTH  += travelH;

      final ExcelColor? bg = bd.surcharge100H > 0.001
          ? _surcharge100
          : bd.surcharge50H > 0.001 ? _surcharge50 : null;

      final cellValues = <CellValue>[
        TextCellValue(df.format(entry.date)),
        TextCellValue(wdf.format(entry.date)),
        TextCellValue(entry.workType.label),
        TextCellValue(tf.format(entry.startTime)),
        TextCellValue(tf.format(entry.endTime!)),
        DoubleCellValue(double.parse(bd.normalH.toStringAsFixed(2))),
        TextCellValue(bd.typeLabel),
        DoubleCellValue(double.parse(bd.surcharge50H.toStringAsFixed(2))),
        DoubleCellValue(double.parse(bd.surcharge100H.toStringAsFixed(2))),
        DoubleCellValue(double.parse(bd.effectiveH.toStringAsFixed(2))),
        km      > 0 ? DoubleCellValue(km)      : TextCellValue(''),
        travelH > 0 ? DoubleCellValue(double.parse(travelH.toStringAsFixed(2)))
                    : TextCellValue(''),
      ];
      for (var c = 0; c < cellValues.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        cell.value = cellValues[c];
        if (bg != null) cell.cellStyle = CellStyle(backgroundColorHex: bg);
      }
      row++;
    }

    // Last month subtotal
    if (curYM != null) {
      _writeSurchargeSubtotal(sheet, row++,
          label: 'Monatssumme', normalH: mNH, s50H: mS50, s100H: mS100,
          effH: mEff, km: mKm, travelH: mTH, bold: true);
    }
    row++; // blank

    // Grand total
    _writeSurchargeSubtotal(sheet, row++,
        label: 'JAHRESSUMME', normalH: totNH, s50H: totS50, s100H: totS100,
        effH: totEff, km: totKm, travelH: totTH, bold: true, grandTotal: true);

    row += 2; // spacer

    // ── Argumentation section ───────────────────────────────────────────────
    void argRow(String label, String value, {bool isHeader = false}) {
      for (var c = 0; c < 12; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        if (c == 0) cell.value = TextCellValue(label);
        if (c == 1) cell.value = TextCellValue(value);
        cell.cellStyle = isHeader
            ? CellStyle(bold: true, backgroundColorHex: _argHeader, fontColorHex: _white)
            : CellStyle(bold: c == 0, backgroundColorHex: _argBg);
      }
      row++;
    }

    argRow('ARGUMENTATION FÜR STUNDENANHEBUNG', '', isHeader: true);
    argRow('Wochensoll (vertraglich)',             _fmtH(weeklyHours));
    argRow('Jahres-Soll (52 Wochen)',              _fmtH(weeklyHours * 52));
    argRow('Jahres-Ist (Netto-Stunden)',
        _fmtH(totNH + totS50 + totS100));
    argRow('Effektiv-Äquivalent gesamt (gewichtet)', _fmtH(totEff));
    row++; // blank within section

    final weeklyEff   = totEff / 52.0;
    final diffTo10h   = weeklyEff - 10.0;
    final yearDiff10h = totEff - 10.0 * 52;
    argRow('Wochen-Äquivalent (effektiv)', _fmtH(weeklyEff));
    argRow('Differenz zum 10h-Wochenziel',
        '${diffTo10h >= 0 ? '+' : ''}${_fmtH(diffTo10h)}');
    argRow('Jahres-Differenz (effektiv vs. 10h-Ziel)',
        '${yearDiff10h >= 0 ? '+' : ''}${_fmtH(yearDiff10h)}');
    row++;

    // ── Monatlicher Ist- vs. Effektivstunden-Vergleich (Tabelle) ─────────────
    final mf2 = DateFormat('MMM yyyy', 'de_AT');
    final monthlyData = <int, ({double istH, double normalH, double s50H, double s100H, double effH})>{};
    for (final e in workEntries) {
      final bd2  = _surchargeBreakdown(e);
      final ym2  = e.date.year * 12 + e.date.month;
      final prev = monthlyData[ym2];
      monthlyData[ym2] = (
        istH:    (prev?.istH    ?? 0) + bd2.normalH + bd2.surcharge50H + bd2.surcharge100H,
        normalH: (prev?.normalH ?? 0) + bd2.normalH,
        s50H:    (prev?.s50H    ?? 0) + bd2.surcharge50H,
        s100H:   (prev?.s100H   ?? 0) + bd2.surcharge100H,
        effH:    (prev?.effH    ?? 0) + bd2.effectiveH,
      );
    }

    // Table header
    const mHeaders = [
      'Monat', 'Ist (h)', 'Normal (h)', '+50% (h)', '+100% (h)',
      'Effektiv (h)', 'Bonus (h)', 'Faktor ×',
    ];
    for (var c = 0; c < mHeaders.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(mHeaders[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _argHeader, fontColorHex: _white);
    }
    row++;

    void writeMonthRow(String label, double ist, double norm, double s50,
        double s100, double eff, {bool isTotals = false}) {
      final bonus  = eff - ist;
      final faktor = ist > 0 ? eff / ist : 0.0;
      final values = <CellValue>[
        TextCellValue(label),
        DoubleCellValue(double.parse(ist.toStringAsFixed(2))),
        DoubleCellValue(double.parse(norm.toStringAsFixed(2))),
        DoubleCellValue(double.parse(s50.toStringAsFixed(2))),
        DoubleCellValue(double.parse(s100.toStringAsFixed(2))),
        DoubleCellValue(double.parse(eff.toStringAsFixed(2))),
        DoubleCellValue(double.parse(bonus.toStringAsFixed(2))),
        DoubleCellValue(double.parse(faktor.toStringAsFixed(2))),
      ];
      for (var c = 0; c < values.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        cell.value = values[c];
        final ExcelColor bg;
        if (isTotals) {
          bg = _blueLight;
        } else if (c == 6) {
          bg = _surcharge50; // Bonus-Spalte amber
        } else if (c == 7) {
          bg = _surcharge100; // Faktor-Spalte pink
        } else {
          bg = _argBg;
        }
        cell.cellStyle = CellStyle(bold: isTotals || c == 0, backgroundColorHex: bg);
      }
      row++;
    }

    for (final entry in monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final rawMonth = entry.key % 12;
      final month3   = rawMonth == 0 ? 12 : rawMonth;
      final year3    = rawMonth == 0 ? (entry.key ~/ 12) - 1 : entry.key ~/ 12;
      writeMonthRow(
        mf2.format(DateTime(year3, month3)),
        entry.value.istH, entry.value.normalH,
        entry.value.s50H, entry.value.s100H, entry.value.effH,
      );
    }
    writeMonthRow('GESAMT', totNH + totS50 + totS100, totNH, totS50, totS100, totEff,
        isTotals: true);
    row++;

    argRow('km gesamt', '${totKm.toStringAsFixed(1)} km');
    argRow('Fahrzeit gesamt', _fmtH(totTH));
    row++;
    argRow('Überstundenpauschale steuerfrei (DN+DG)',
        'bis ~400 €/Monat gem. § 68 EStG (ab 1.1.2024)');

    // ── Column widths ───────────────────────────────────────────────────────
    sheet.setColumnWidth(0,  14); // Datum
    sheet.setColumnWidth(1,  14); // Wochentag
    sheet.setColumnWidth(2,  16); // Tätigkeitsart
    sheet.setColumnWidth(3,   8); // Beginn
    sheet.setColumnWidth(4,   8); // Ende
    sheet.setColumnWidth(5,  11); // Normal (h)
    sheet.setColumnWidth(6,  18); // Zuschlagstyp
    sheet.setColumnWidth(7,  11); // +50%
    sheet.setColumnWidth(8,  11); // +100%
    sheet.setColumnWidth(9,  12); // Effektiv
    sheet.setColumnWidth(10,  8); // km
    sheet.setColumnWidth(11, 12); // Fahrzeit
  }

  String _fmtH(double h) {
    final abs = h.abs();
    final hh  = abs.floor();
    final mm  = ((abs - hh) * 60).round();
    final sign = h < 0 ? '-' : '';
    return '${sign}${hh}h ${mm.toString().padLeft(2, '0')}m';
  }

  Future<File> _save(Excel excel, String employer, String suffix) async {
    final dir   = await getApplicationDocumentsDirectory();
    final safe  = employer.replaceAll(RegExp(r'[^\w]'), '_');
    final name  = safe.isNotEmpty ? '${safe}_$suffix' : 'Zeiterfassung_$suffix';
    final file  = File('${dir.path}/$name.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('XLSX-Kodierung fehlgeschlagen');
    await file.writeAsBytes(bytes);
    return file;
  }
}
