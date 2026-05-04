import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracked_location.dart';

typedef GeofenceCallback = void Function(TrackedLocation location, bool entered);

class GeofencingService {
  GeofencingService._();
  static final GeofencingService instance = GeofencingService._();

  GeofenceCallback? onZoneChange;

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _isRunning = false;

  bool get isTracking => _isRunning;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
        const InitializationSettings(android: androidInit));

    if (!Platform.isAndroid) return;

    // Restore tracking state after app restart.
    _isRunning = await FlutterBackgroundService().isRunning();

    // Forward zone change events from background isolate to onZoneChange.
    FlutterBackgroundService().on('zoneChange').listen((data) {
      if (data == null) return;
      onZoneChange?.call(_minimalLocation(data), data['entered'] as bool);
    });
  }

  /// Start the persistent foreground GPS service.
  Future<bool> startTracking(List<TrackedLocation> locations) async {
    if (!Platform.isAndroid) return false;

    final permission = await _checkPermission();
    if (!permission) return false;

    await FlutterBackgroundService().startService();
    // Short delay so the isolate is ready before receiving locations.
    await Future.delayed(const Duration(milliseconds: 400));
    _sendLocations(locations);

    _isRunning = true;
    return true;
  }

  void stopTracking() {
    if (!Platform.isAndroid) return;
    FlutterBackgroundService().invoke('stop');
    _isRunning = false;
  }

  /// Push updated location list to the running background service.
  void updateLocations(List<TrackedLocation> locations) {
    if (!Platform.isAndroid || !_isRunning) return;
    _sendLocations(locations);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _sendLocations(List<TrackedLocation> locs) {
    FlutterBackgroundService().invoke('setLocations', {
      'locations': locs.map((l) => {
        'id': l.id,
        'name': l.name,
        'latitude': l.latitude,
        'longitude': l.longitude,
        'radiusMeters': l.radiusMeters,
        'employerId': l.employerId,
      }).toList(),
    });
  }

  TrackedLocation _minimalLocation(Map<String, dynamic> data) => TrackedLocation(
        id: data['locationId'] as String,
        name: data['locationName'] as String,
        latitude: 0,
        longitude: 0,
        radiusMeters: 0,
        employerId: data['employerId'] as String?,
      );

  Future<bool> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }
}
