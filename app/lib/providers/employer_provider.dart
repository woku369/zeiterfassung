import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/employer.dart';
import '../database/database_helper.dart';

class EmployerProvider extends ChangeNotifier {
  List<Employer> _employers = [];
  Employer? _active;

  List<Employer> get employers => _employers;
  Employer? get active => _active;

  Future<void> load() async {
    _employers = await DatabaseHelper.instance.getEmployers();
    if (_employers.isNotEmpty) _active ??= _employers.first;
    notifyListeners();
  }

  Future<void> reload() async {
    final activeId = _active?.id;
    _employers = await DatabaseHelper.instance.getEmployers();
    _active = _employers.firstWhere(
      (e) => e.id == activeId,
      orElse: () => _employers.isNotEmpty ? _employers.first : _active!,
    );
    notifyListeners();
  }

  Future<void> add(String name, double weeklyHours,
      {int fiscalYearStartMonth = 4, int vacationDaysPerYear = 25}) async {
    final e = Employer(
        id: const Uuid().v4(),
        name: name,
        weeklyHours: weeklyHours,
        fiscalYearStartMonth: fiscalYearStartMonth,
        vacationDaysPerYear: vacationDaysPerYear);
    await DatabaseHelper.instance.insertEmployer(e);
    _employers.add(e);
    _active ??= e;
    notifyListeners();
  }

  Future<void> update(Employer e) async {
    await DatabaseHelper.instance.updateEmployer(e);
    final idx = _employers.indexWhere((x) => x.id == e.id);
    if (idx != -1) _employers[idx] = e;
    if (_active?.id == e.id) _active = e;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await DatabaseHelper.instance.deleteEmployer(id);
    _employers.removeWhere((e) => e.id == id);
    if (_active?.id == id) _active = _employers.isNotEmpty ? _employers.first : null;
    notifyListeners();
  }

  void setActive(Employer e) {
    _active = e;
    notifyListeners();
  }
}
