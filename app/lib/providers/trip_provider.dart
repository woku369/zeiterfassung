import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/trip_record.dart';
import '../services/nominatim_service.dart';
import '../services/geofencing_background.dart';

class TripProvider extends ChangeNotifier {
  List<TripRecord> _trips = [];
  bool _trackingEnabled = false;

  List<TripRecord> get trips => _trips;
  bool get trackingEnabled => _trackingEnabled;

  /// Running trip (no end_time yet).
  TripRecord? get openTrip =>
      _trips.where((t) => !t.isComplete).firstOrNull;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _trackingEnabled = prefs.getBool(kTripTrackingKey) ?? false;
    _trips = await DatabaseHelper.instance.getTrips();
    notifyListeners();
  }

  Future<void> setTrackingEnabled(bool v) async {
    _trackingEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kTripTrackingKey, v);
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    await DatabaseHelper.instance.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> linkEntry(String tripId, String entryId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;
    final updated = _trips[idx].copyWith(linkedEntryId: entryId);
    await DatabaseHelper.instance.updateTrip(updated);
    _trips[idx] = updated;
    notifyListeners();
  }

  /// Lazily resolve addresses for a trip via Nominatim.
  Future<void> resolveAddresses(TripRecord trip) async {
    final idx = _trips.indexWhere((t) => t.id == trip.id);
    if (idx == -1) return;
    var t = _trips[idx];
    bool changed = false;

    if (t.startAddress == null) {
      final addr =
          await NominatimService.reverseGeocode(t.startLat, t.startLng);
      if (addr != null) {
        t = t.copyWith(startAddress: addr);
        changed = true;
      }
    }
    if (t.endAddress == null && t.endLat != null && t.endLng != null) {
      final addr =
          await NominatimService.reverseGeocode(t.endLat!, t.endLng!);
      if (addr != null) {
        t = t.copyWith(endAddress: addr);
        changed = true;
      }
    }
    if (changed) {
      await DatabaseHelper.instance.updateTrip(t);
      _trips[idx] = t;
      notifyListeners();
    }
  }
}
