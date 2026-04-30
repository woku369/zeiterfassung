import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/tracked_location.dart';
import '../models/work_type.dart';
import '../database/database_helper.dart';

class LocationProvider extends ChangeNotifier {
  List<TrackedLocation> _locations = [];

  List<TrackedLocation> get locations => _locations;
  List<TrackedLocation> get activeLocations =>
      _locations.where((l) => l.isActive).toList();

  Future<void> load() async {
    _locations = await DatabaseHelper.instance.getLocations();
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required double latitude,
    required double longitude,
    double radiusMeters = 200.0,
    WorkType workType = WorkType.offsite,
  }) async {
    final loc = TrackedLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      workType: workType,
    );
    await DatabaseHelper.instance.insertLocation(loc);
    _locations.add(loc);
    _locations.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> update(TrackedLocation loc) async {
    await DatabaseHelper.instance.updateLocation(loc);
    final idx = _locations.indexWhere((l) => l.id == loc.id);
    if (idx != -1) _locations[idx] = loc;
    _locations.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await DatabaseHelper.instance.deleteLocation(id);
    _locations.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> toggleActive(TrackedLocation loc) async {
    await update(loc.copyWith(isActive: !loc.isActive));
  }
}
