import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Remove duplicates first so sync propagates the deletions.
    await DatabaseHelper.instance.deduplicateLocations();
    _locations = await DatabaseHelper.instance.getLocations();
    if (_locations.isEmpty) await _seedDefaultLocations();
    await _ensureSpecialLocations();
    notifyListeners();
  }

  /// Idempotente Pflege-Standorte, die nicht zur Erst-Befüllung gehören
  /// (z.B. externe Lohnabfüller). Werden bei jedem Load gegengeprüft und nur
  /// einmalig angelegt – Identifikation per exakter Namensgleichheit.
  Future<void> _ensureSpecialLocations() async {
    // getAllLocationsForSync includes soft-deleted entries – avoids recreating
    // a location that the user has explicitly deleted.
    final allLocs = await DatabaseHelper.instance.getAllLocationsForSync();
    if (allLocs.any((l) => l.name == 'Pfau Brennerei Klagenfurt')) return;

    // Gurktaler AG als Arbeitgeber zuordnen, sofern vorhanden – Aufwand am
    // Lohnabfüller wird voll der Gurktaler AG zugerechnet.
    final employers = await DatabaseHelper.instance.getEmployers();
    String? gurktalerId;
    for (final e in employers) {
      if (e.name.toLowerCase().contains('gurktaler')) {
        gurktalerId = e.id;
        break;
      }
    }

    final loc = TrackedLocation(
      id: const Uuid().v4(),
      name: 'Pfau Brennerei Klagenfurt',
      latitude: 46.6415142,
      longitude: 14.2860346,
      radiusMeters: 150,
      workType: WorkType.offsite,
      employerId: gurktalerId,
    );
    await DatabaseHelper.instance.insertLocation(loc);
    _locations.add(loc);
    _locations.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _seedDefaultLocations() async {
    // Only seed on a truly fresh install with no NAS configured.
    // Uses SharedPreferences global_nas_url (replaces the old employer.nasUrl
    // check that broke when NAS config was moved to global prefs in v1.8).
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('global_nas_url') ?? '').isNotEmpty) return;
    if (prefs.getBool('locations_seeded') ?? false) return;
    final seeds = [
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Homeoffice Glantscha',
        latitude: 46.7476,
        longitude: 14.0824,
        radiusMeters: 150,
        workType: WorkType.homeoffice,
        // employer_id = null → gilt für alle Arbeitgeber
      ),
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Hauptarbeitsstelle Labegg',
        latitude: 46.7787,
        longitude: 14.5308,
        radiusMeters: 150,
        workType: WorkType.office,
      ),
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Hauptarbeitsstelle Brückl',
        latitude: 46.7626,
        longitude: 14.5364,
        radiusMeters: 150,
        workType: WorkType.office,
      ),
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Gurktaler Domplatz',
        latitude: 46.8757,
        longitude: 14.2862,
        radiusMeters: 200,
        workType: WorkType.offsite,
      ),
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Gurktaler Kräutergarten',
        latitude: 46.8773,
        longitude: 14.2842,
        radiusMeters: 250,
        workType: WorkType.offsite,
      ),
      TrackedLocation(
        id: const Uuid().v4(),
        name: 'Gurktaler Büro Hemmaweg',
        latitude: 46.8749,
        longitude: 14.2878,
        radiusMeters: 150,
        workType: WorkType.office,
      ),
    ];
    for (final loc in seeds) {
      await DatabaseHelper.instance.insertLocation(loc);
    }
    _locations = seeds;
    await prefs.setBool('locations_seeded', true);
  }

  Future<void> add({
    required String name,
    required double latitude,
    required double longitude,
    double radiusMeters = 200.0,
    WorkType workType = WorkType.offsite,
    String? employerId,
  }) async {
    final loc = TrackedLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      workType: workType,
      employerId: employerId,
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
