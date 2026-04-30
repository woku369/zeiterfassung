import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracked_location.dart';

/// Callback fired when a location zone is entered or left.
/// [location] is the affected zone, [entered] is true on enter, false on leave.
typedef GeofenceCallback = void Function(TrackedLocation location, bool entered);

class GeofencingService {
  GeofencingService._();
  static final GeofencingService instance = GeofencingService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _positionSub;
  GeofenceCallback? onZoneChange;

  // Tracks which location IDs the user is currently inside.
  final Set<String> _inside = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'geofence',
      'Standort-Erkennung',
      description: 'Benachrichtigungen beim Betreten/Verlassen von Standorten',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Start listening to GPS updates and check against [locations].
  Future<bool> startTracking(List<TrackedLocation> locations) async {
    await init();

    final permission = await _checkPermission();
    if (!permission) return false;

    _positionSub?.cancel();
    _inside.clear();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) => _onPosition(pos, locations));

    return true;
  }

  void updateLocations(List<TrackedLocation> locations) {
    // Called when the location list changes while tracking is active.
    // Resets inside-state for removed locations.
    final ids = locations.map((l) => l.id).toSet();
    _inside.removeWhere((id) => !ids.contains(id));
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _inside.clear();
  }

  bool get isTracking => _positionSub != null;

  void _onPosition(Position pos, List<TrackedLocation> locations) {
    for (final loc in locations.where((l) => l.isActive)) {
      final dist = _haversineMeters(
        pos.latitude, pos.longitude,
        loc.latitude, loc.longitude,
      );
      final wasInside = _inside.contains(loc.id);
      final nowInside = dist <= loc.radiusMeters;

      if (!wasInside && nowInside) {
        _inside.add(loc.id);
        _notify(
          loc.id.hashCode,
          'Standort: ${loc.name}',
          'Arbeitszeit jetzt starten?',
        );
        onZoneChange?.call(loc, true);
      } else if (wasInside && !nowInside) {
        _inside.remove(loc.id);
        _notify(
          loc.id.hashCode + 1,
          'Standort verlassen: ${loc.name}',
          'Arbeitszeit beenden?',
        );
        onZoneChange?.call(loc, false);
      }
    }
  }

  void _notify(int id, String title, String body) {
    _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence',
          'Standort-Erkennung',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Haversine formula – returns distance in meters.
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
