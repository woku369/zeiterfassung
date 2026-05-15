import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../services/holiday_service.dart';

class ImportResult {
  final List<TimeEntry> entries;
  final List<String> errors;
  final String? period;
  ImportResult({required this.entries, required this.errors, this.period});
}

class ImportService {
  static final ImportService instance = ImportService._();
  ImportService._();

  ImportResult importFromXlsx(List<int> bytes, {String? employerId}) {
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      return ImportResult(entries: [], errors: ['Datei konnte nicht geöffnet werden: $e']);
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    final rows = sheet.rows;
    if (rows.isEmpty) return ImportResult(entries: [], errors: ['Tabelle ist leer']);

    // Try Stempeluhr 2.1 format first
    final stempeluhr = _parseStempeluhr21(rows, employerId: employerId);
    if (stempeluhr != null) return stempeluhr;

    // Stempeluhr detection failed — return debug dump of first 12 rows
    return _debugDump(rows);
  }

  // ── Stempeluhr 2.1 ──────────────────────────────────────────────────────────

  ImportResult? _parseStempeluhr21(List<List<Data?>> rows,
      {String? employerId}) {
    int? year, month;
    int headerRow = -1;
    int firstDataRow = -1;
    int colTag = 0;

    // Pattern: "01 Mi", "5 Sa", "29 Fr" — day number + space + weekday abbrev
    final dayRowPattern = RegExp(r'^\d{1,2}\s+[A-Za-zÄÖÜäöü]', unicode: true);

    // Scan ALL rows, ALL columns — find first cell matching day+weekday pattern
    for (var ri = 0; ri < rows.length; ri++) {
      final row = rows[ri];
      for (var ci = 0; ci < row.length; ci++) {
        final cell = (row[ci]?.value?.toString() ?? '').trim();
        if (dayRowPattern.hasMatch(cell)) {
          firstDataRow = ri;
          headerRow = ri - 1;
          colTag = ci; // remember which column holds the day+weekday
          break;
        }
      }
      if (firstDataRow >= 0) break;
    }

    if (firstDataRow < 0) return null; // Not Stempeluhr 2.1
    // If data starts on row 0, there's no header row — use positional defaults
    if (headerRow < 0) headerRow = -1;

    // Scan all rows before the data for Abrechnungszeitraum (MM.YYYY pattern)
    final mmYyyyPattern = RegExp(r'(\d{2})\.(\d{4})');
    for (var ri = 0; ri < firstDataRow; ri++) {
      final cells = rows[ri].map((c) => c?.value?.toString() ?? '').toList();
      final rowText = cells.join(' ');
      final m = mmYyyyPattern.firstMatch(rowText);
      if (m != null) {
        final candidateMonth = int.parse(m.group(1)!);
        final candidateYear = int.parse(m.group(2)!);
        if (candidateMonth >= 1 && candidateMonth <= 12 &&
            candidateYear >= 2000 && candidateYear <= 2100) {
          month = candidateMonth;
          year = candidateYear;
          break;
        }
      }
    }

    // Detect column indices from header row; fall back to Stempeluhr positional defaults
    // colTag already set during row detection above
    int? colOrt, colKommen, colGehen, colPause, colNotiz;

    if (headerRow >= 0) {
      final hRow = rows[headerRow];
      for (var ci = 0; ci < hRow.length; ci++) {
        final v = hRow[ci]?.value?.toString().toLowerCase().trim() ?? '';
        if (v.contains('tag')) colTag = ci;
        if ((v.contains('e-ort') || v.contains('einsatzort') || v.contains('ort')) &&
            colOrt == null) colOrt = ci;
        if ((v.contains('kommen') || v.contains('beginn') || v.contains('start')) &&
            colKommen == null) colKommen = ci;
        if ((v.contains('gehen') || v.contains('ende') || v == 'bis') &&
            colGehen == null) colGehen = ci;
        if (v.contains('pause') && colPause == null) colPause = ci;
        if ((v.contains('notiz') || v.contains('bemerkung') || v.contains('tätigkeit')) &&
            colNotiz == null) colNotiz = ci;
      }
    }

    // If header scan didn't find time columns, use Stempeluhr 2.1 positional defaults
    // Typical layout: Tag | E-Ort | Kommen | Gehen | Pause | (net) | Notiz
    final int colKommenFinal = colKommen ?? (colTag + 2);
    final int colGehenFinal = colGehen ?? (colTag + 3);
    final int colPauseFinal = colPause ?? (colTag + 4);
    final int colNotizFinal = colNotiz ?? (colTag + 6);

    final entries = <TimeEntry>[];
    final errors = <String>[];
    final seenKeys = <String>{}; // deduplication within this file

    for (var ri = firstDataRow; ri < rows.length; ri++) {
      final row = rows[ri];
      if (row.isEmpty) continue;

      final tagStr = _cellStr(row, colTag).trim();
      if (tagStr.isEmpty) continue;

      // "01 Mi", "29 Mi", "5 Sa" → extract leading day number
      final dayMatch = RegExp(r'^(\d{1,2})').firstMatch(tagStr);
      if (dayMatch == null) continue;
      final day = int.tryParse(dayMatch.group(1)!);
      if (day == null || day < 1 || day > 31) continue;

      // Build date from header Abrechnungszeitraum
      if (year == null || month == null) {
        errors.add('Zeile ${ri + 1}: Kein Abrechnungszeitraum in der Datei gefunden');
        break;
      }

      DateTime date;
      try {
        date = DateTime(year, month, day);
        // Guard against days that overflow (e.g. 31 in April)
        if (date.day != day) continue;
      } catch (_) {
        continue;
      }

      final kommenStr = _cellStr(row, colKommenFinal).trim();
      if (kommenStr.isEmpty) continue; // No work this day

      final startTime = _parseTime(date, kommenStr);
      if (startTime == null) {
        errors.add('Zeile ${ri + 1}: Startzeit "$kommenStr" nicht erkannt');
        continue;
      }

      DateTime? endTime;
      final gehenStr = _cellStr(row, colGehenFinal).trim();
      if (gehenStr.isNotEmpty) {
        endTime = _parseTime(date, gehenStr);
        if (endTime != null && endTime.isBefore(startTime)) {
          endTime = endTime.add(const Duration(days: 1));
        }
      }

      final breakMinutes = _parseBreakDecimal(_cellStr(row, colPauseFinal));
      final note = _cellStr(row, colNotizFinal).trim();
      final ortRaw = colOrt != null ? _cellStr(row, colOrt!).trim() : '';
      final workType = _ortToWorkType(ortRaw);
      final dayType = _deriveDayType(date);

      // Deduplication key: date + start time (handles two entries same day)
      final dedupKey =
          '${date.toIso8601String().substring(0, 10)}|${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
      if (seenKeys.contains(dedupKey)) continue;
      seenKeys.add(dedupKey);

      // Deterministic ID so re-importing the same file never creates duplicates
      final stableId = const Uuid().v5(Uuid.NAMESPACE_URL, dedupKey);

      entries.add(TimeEntry(
        id: stableId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        workType: workType,
        dayType: dayType,
        note: note,
        employerId: employerId,
        createdAt: DateTime.now(),
      ));
    }

    final period = (year != null && month != null)
        ? '${_monthName(month!)} $year'
        : null;

    return ImportResult(entries: entries, errors: errors, period: period);
  }

  // ── Debug dump (shown when format not recognized) ────────────────────────────

  ImportResult _debugDump(List<List<Data?>> rows) {
    final lines = <String>['FORMAT NICHT ERKANNT – Zellinhalte (erste 12 Zeilen):'];
    for (var ri = 0; ri < rows.length.clamp(0, 12); ri++) {
      final row = rows[ri];
      final cells = <String>[];
      for (var ci = 0; ci < row.length.clamp(0, 8); ci++) {
        final v = row[ci]?.value;
        final type = v == null ? 'null' : v.runtimeType.toString().replaceAll('CellValue', '');
        final s = _cellStr(row, ci);
        cells.add('[$ci:$type="${s.length > 15 ? s.substring(0, 15) : s}"]');
      }
      lines.add('Z${ri + 1}: ${cells.join(' ')}');
    }
    return ImportResult(entries: [], errors: lines);
  }

  // ── Generic fallback ─────────────────────────────────────────────────────────

  ImportResult _parseGeneric(List<List<Data?>> rows, {String? employerId}) {
    final colMap = _detectColumnsGeneric(rows);
    if (colMap['date'] == null || colMap['start'] == null) {
      return ImportResult(
        entries: [],
        errors: ['Spalten "Datum" und "Beginn/Kommen" konnten nicht erkannt werden.'],
      );
    }

    final entries = <TimeEntry>[];
    final errors = <String>[];
    final headerRow = colMap['_headerRow'] as int? ?? 0;
    final seenKeys = <String>{};

    for (var i = headerRow + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final dateStr = _cellStr(row, colMap['date']! as int).trim();
        if (dateStr.isEmpty) continue;

        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Zeile ${i + 1}: Datum "$dateStr" nicht erkannt');
          continue;
        }

        final startStr = _cellStr(row, colMap['start']! as int).trim();
        final startTime = _parseTime(date, startStr);
        if (startTime == null) {
          errors.add('Zeile ${i + 1}: Startzeit "$startStr" nicht erkannt');
          continue;
        }

        DateTime? endTime;
        if (colMap['end'] != null) {
          final endStr = _cellStr(row, colMap['end']! as int).trim();
          if (endStr.isNotEmpty) {
            endTime = _parseTime(date, endStr);
            if (endTime != null && endTime.isBefore(startTime)) {
              endTime = endTime.add(const Duration(days: 1));
            }
          }
        }

        final breakMinutes = colMap['break'] != null
            ? _parseBreakDecimal(_cellStr(row, colMap['break']! as int))
            : 0;

        final note =
            colMap['note'] != null ? _cellStr(row, colMap['note']! as int).trim() : '';

        final dedupKey =
            '${date.toIso8601String().substring(0, 10)}|${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
        if (seenKeys.contains(dedupKey)) continue;
        seenKeys.add(dedupKey);

        entries.add(TimeEntry(
          id: const Uuid().v5(Uuid.NAMESPACE_URL, dedupKey),
          date: date,
          startTime: startTime,
          endTime: endTime,
          breakMinutes: breakMinutes,
          workType: WorkType.other,
          dayType: _deriveDayType(date),
          note: note,
          employerId: employerId,
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        errors.add('Zeile ${i + 1}: Fehler ($e)');
      }
    }

    return ImportResult(entries: entries, errors: []);
  }

  Map<String, dynamic> _detectColumnsGeneric(List<List<Data?>> rows) {
    const dateNames = ['datum', 'date', 'tag'];
    const startNames = ['beginn', 'start', 'von', 'anfang', 'kommen'];
    const endNames = ['ende', 'end', 'bis', 'gehen'];
    const breakNames = ['pause', 'break'];
    const noteNames = ['notiz', 'bemerkung', 'tätigkeit', 'kommentar'];

    for (var ri = 0; ri < rows.length.clamp(0, 10); ri++) {
      final row = rows[ri];
      final result = <String, dynamic>{'_headerRow': ri};
      for (var ci = 0; ci < row.length; ci++) {
        final v = row[ci]?.value?.toString().toLowerCase().trim() ?? '';
        if (dateNames.any((n) => v.contains(n))) result['date'] ??= ci;
        if (startNames.any((n) => v.contains(n))) result['start'] ??= ci;
        if (endNames.any((n) => v.contains(n))) result['end'] ??= ci;
        if (breakNames.any((n) => v.contains(n))) result['break'] ??= ci;
        if (noteNames.any((n) => v.contains(n))) result['note'] ??= ci;
      }
      if (result['date'] != null && result['start'] != null) return result;
    }
    // Last-resort Stempeluhr column order
    return {'_headerRow': 0, 'date': 0, 'start': 1, 'end': 2, 'break': 3, 'note': 5};
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  WorkType _ortToWorkType(String ort) {
    final o = ort.toLowerCase();
    if (o.contains('home') || o == 'ho') return WorkType.homeoffice;
    if (o.contains('mobil') || o.contains('außen')) return WorkType.travel;
    if (o.isNotEmpty) return WorkType.offsite;
    return WorkType.other;
  }

  DayType _deriveDayType(DateTime date) {
    if (HolidayService.instance.isHoliday(date)) return DayType.holiday;
    if (date.weekday == 6) return DayType.saturday;
    if (date.weekday == 7) return DayType.sunday;
    return DayType.workday;
  }

  String _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final v = row[col]?.value;
    if (v == null) return '';
    if (v is DateCellValue) {
      return '${v.day.toString().padLeft(2, '0')}.${v.month.toString().padLeft(2, '0')}.${v.year}';
    }
    if (v is TimeCellValue) {
      return '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
    }
    if (v is DoubleCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    return v.toString().trim();
  }

  DateTime? _parseDate(String s) {
    s = s.trim();
    final r1 = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
    var m = r1.firstMatch(s);
    if (m != null) return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    final r2 = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    m = r2.firstMatch(s);
    if (m != null) return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return null;
  }

  DateTime? _parseTime(DateTime date, String s) {
    s = s.trim().replaceAll(',', ':');
    final m = RegExp(r'^(\d{1,2})[:\.](\d{2})').firstMatch(s);
    if (m == null) return null;
    return DateTime(date.year, date.month, date.day,
        int.parse(m[1]!), int.parse(m[2]!));
  }

  int _parseBreakDecimal(String s) {
    s = s.trim().replaceAll(',', '.');
    if (s.isEmpty || s == '0' || s == '0.00') return 0;
    // HH:MM format
    final r = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m = r.firstMatch(s);
    if (m != null) return int.parse(m[1]!) * 60 + int.parse(m[2]!);
    // Decimal hours (e.g. "0.5" = 30 min, "1.00" = 60 min)
    final d = double.tryParse(s);
    if (d != null) return (d * 60).round();
    return 0;
  }

  String _monthName(int m) {
    const names = [
      '', 'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return m >= 1 && m <= 12 ? names[m] : m.toString();
  }
}
