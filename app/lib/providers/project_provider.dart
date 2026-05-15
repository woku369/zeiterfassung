import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/project.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];

  List<Project> get projects => _projects;

  List<Project> forEmployer(String? employerId) {
    if (employerId == null) return [];
    return _projects
        .where((p) => p.employerId == employerId)
        .toList()
      ..sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
  }

  Future<void> load() async {
    _projects = await DatabaseHelper.instance.getProjects();
    notifyListeners();
  }

  Future<void> ensureGurktalerProjects() async {
    final employers = await DatabaseHelper.instance.getEmployers();
    for (final e in employers) {
      if (e.name.toLowerCase().contains('gurktaler')) {
        final existing = await DatabaseHelper.instance.getProjects(employerId: e.id);
        if (existing.isEmpty) {
          await _seedProjects(e.id);
        }
        break;
      }
    }
    await load();
  }

  Future<void> _seedProjects(String employerId) async {
    const names = [
      'Führungen',
      'Kräutergarten',
      'Mazeration',
      'Kleinserie',
      'Produktentwicklung',
      'Rezepturoptimierung',
      'Administration',
    ];
    for (var i = 0; i < names.length; i++) {
      await DatabaseHelper.instance.insertProject(
        Project.create(name: names[i], employerId: employerId, sortOrder: i),
      );
    }
  }

  Future<void> add(String name, String? employerId) async {
    final existing = forEmployer(employerId);
    await DatabaseHelper.instance.insertProject(
      Project.create(name: name, employerId: employerId, sortOrder: existing.length),
    );
    await load();
  }

  Future<void> remove(String id) async {
    await DatabaseHelper.instance.deleteProject(id);
    await load();
  }

  Future<void> rename(String id, String newName) async {
    final p = _projects.firstWhere((p) => p.id == id);
    await DatabaseHelper.instance.updateProject(p.copyWith(
      name: newName,
      updatedAt: DateTime.now().toIso8601String(),
    ));
    await load();
  }
}
