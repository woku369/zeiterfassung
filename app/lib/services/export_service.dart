import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/surcharge_service.dart';

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
  static final _title    = ExcelColor.fromHexString('#0D47A1');

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Monthly XLSX — Monat mit Kopfzeile, KW-Summen, Monatssumme.
  Future<File> exportMonth({
    required List<TimeEntry> entries,
    required int year,
    required int month,
    String employerName = '',
    double weeklyHours = 40,
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
    row = _writeDetailRows(sheet, row, entries, weeklyHours);

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
    _writeDetailRows(detail, dRow, workEntries, weeklyHours);
    _setDetailColumnWidths(detail);

    return _save(excel, employerName, fyLabel.replaceAll('/', '-'));
  }

  /// Custom date range XLSX.
  Future<File> exportRange({
    required List<TimeEntry> entries,
    required DateTime from,
    required DateTime to,
    String employerName = '',
    double weeklyHours = 40,
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
    _writeDetailRows(sheet, row, entries, weeklyHours);

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
    // Blank the other columns with same bg
    for (var c = 1; c < 10; c++) {
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
                     'Netto (h)', 'Tätigkeit', 'Tagtyp', 'Notiz', 'km'];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: _blue, fontColorHex: _white);
    }
  }

  /// Writes entries with KW-Summen. Returns next free row index.
  int _writeDetailRows(Sheet sheet, int startRow, List<TimeEntry> entries, double weeklyHours) {
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
        TextCellValue(_fmtH(hours)), '', '', '', ''];
    for (var c = 0; c < 10; c++) {
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
