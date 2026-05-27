import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../database/database_helper.dart';

class TimeEntryProvider extends ChangeNotifier {
  List<TimeEntry> _entries = [];
  TimeEntry? _activeEntry;
  TimeEntry? _staleOpenEntry;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _employerId;
  VoidCallback? _syncTrigger;

  List<TimeEntry> get entries => _entries;
  TimeEntry? get activeEntry => _activeEntry;
  /// Open entry from before today (across all employers). Null when none exists.
  TimeEntry? get staleOpenEntry => _staleOpenEntry;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  String? get employerId => _employerId;

  void setSyncTrigger(VoidCallback trigger) => _syncTrigger = trigger;

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
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // Only today's open entries count as "active" (running timer, clock-out button).
    // Past open entries are shown via staleOpenEntry (orange banner) instead.
    _activeEntry = _entries.where((e) => e.isActive && !e.date.isBefore(todayDate)).firstOrNull
        ?? await DatabaseHelper.instance.getTodayActiveEntry(today);
    _staleOpenEntry = await DatabaseHelper.instance.getStaleOpenEntry(today);
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
    _syncTrigger?.call();
    return entry;
  }

  Future<void> clockOut({int breakMinutes = 0, String note = ''}) async {
    if (_activeEntry == null) return;
    final now = DateTime.now();
    final updated = _activeEntry!.copyWith(
      endTime: now,
      breakMinutes: breakMinutes,
      note: note.isNotEmpty ? note : (_activeEntry!.note),
    );
    await DatabaseHelper.instance.updateEntry(updated);
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) _entries[idx] = updated;
    _activeEntry = null;
    notifyListeners();
    _syncTrigger?.call();
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
    _syncTrigger?.call();
  }

  Future<void> updateEntry(TimeEntry entry) async {
    await DatabaseHelper.instance.updateEntry(entry);
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _entries[idx] = entry;
    if (_activeEntry?.id == entry.id) {
      _activeEntry = entry.isActive ? entry : null;
    }
    notifyListeners();
    _syncTrigger?.call();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    _entries.removeWhere((e) => e.id == id);
    if (_activeEntry?.id == id) _activeEntry = null;
    notifyListeners();
    _syncTrigger?.call();
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
    // Normalize to midnight so entries whose date is stored as midnight are
    // not accidentally excluded when monday carries a non-zero time component.
    final mon = DateTime(monday.year, monday.month, monday.day);
    final sun = mon.add(const Duration(days: 6));
    return _entries
        .where((e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return !d.isBefore(mon) && !d.isAfter(sun);
        })
        .fold(0.0, (sum, e) => sum + e.totalHours);
  }

  double totalKmForMonth() =>
      _entries.fold(0.0, (sum, e) => sum + (e.distanceKm ?? 0.0));
}
