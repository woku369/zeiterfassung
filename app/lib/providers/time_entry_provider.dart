import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../database/database_helper.dart';

class TimeEntryProvider extends ChangeNotifier {
  List<TimeEntry> _entries = [];
  TimeEntry? _activeEntry;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _employerId;

  List<TimeEntry> get entries => _entries;
  TimeEntry? get activeEntry => _activeEntry;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  String? get employerId => _employerId;

  /// Called by ProxyProvider when the active employer changes.
  void setActiveEmployer(String? employerId) {
    if (_employerId == employerId) return;
    _employerId = employerId;
    loadMonth(_selectedYear, _selectedMonth);
  }

  Future<void> loadMonth(int year, int month) async {
    _selectedYear = year;
    _selectedMonth = month;
    _entries = await DatabaseHelper.instance
        .getEntriesForMonth(year, month, employerId: _employerId);
    _activeEntry = _entries.where((e) => e.isActive).firstOrNull;
    notifyListeners();
  }

  Future<void> refresh() => loadMonth(_selectedYear, _selectedMonth);

  Future<TimeEntry> clockIn(
      {WorkType workType = WorkType.homeoffice,
      DayType dayType = DayType.workday}) async {
    final now = DateTime.now();
    final entry = TimeEntry(
      id: const Uuid().v4(),
      date: DateTime(now.year, now.month, now.day),
      startTime: now,
      workType: workType,
      dayType: dayType,
      employerId: _employerId,
      createdAt: now,
    );
    await DatabaseHelper.instance.insertEntry(entry);
    _activeEntry = entry;
    if (now.year == _selectedYear && now.month == _selectedMonth) {
      _entries.insert(0, entry);
    }
    notifyListeners();
    return entry;
  }

  Future<void> clockOut({int breakMinutes = 0, String note = ''}) async {
    if (_activeEntry == null) return;
    final updated = _activeEntry!.copyWith(
      endTime: DateTime.now(),
      breakMinutes: breakMinutes,
      note: note,
    );
    await DatabaseHelper.instance.updateEntry(updated);
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) _entries[idx] = updated;
    _activeEntry = null;
    notifyListeners();
  }

  Future<void> addEntry(TimeEntry entry) async {
    final withEmployer = _employerId != null && entry.employerId == null
        ? entry.copyWith(employerId: _employerId)
        : entry;
    await DatabaseHelper.instance.insertEntry(withEmployer);
    if (withEmployer.date.year == _selectedYear &&
        withEmployer.date.month == _selectedMonth) {
      _entries.insert(0, withEmployer);
      _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
    notifyListeners();
  }

  Future<void> updateEntry(TimeEntry entry) async {
    await DatabaseHelper.instance.updateEntry(entry);
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _entries[idx] = entry;
    if (_activeEntry?.id == entry.id) {
      _activeEntry = entry.isActive ? entry : null;
    }
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    _entries.removeWhere((e) => e.id == id);
    if (_activeEntry?.id == id) _activeEntry = null;
    notifyListeners();
  }

  Map<String, List<TimeEntry>> get entriesByWeek {
    final result = <String, List<TimeEntry>>{};
    for (final e in _entries) {
      final monday = e.date.subtract(Duration(days: e.date.weekday - 1));
      final key = monday.toIso8601String().substring(0, 10);
      result.putIfAbsent(key, () => []).add(e);
    }
    return result;
  }

  double totalHoursForMonth() =>
      _entries.fold(0.0, (sum, e) => sum + e.totalHours);

  double totalHoursForWeek(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return _entries
        .where((e) => !e.date.isBefore(monday) && !e.date.isAfter(sunday))
        .fold(0.0, (sum, e) => sum + e.totalHours);
  }

  double totalKmForMonth() =>
      _entries.fold(0.0, (sum, e) => sum + (e.distanceKm ?? 0.0));
}
