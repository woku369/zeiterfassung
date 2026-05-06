import 'dart:async';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

// Kanal-IDs als Konstanten, damit sie an beiden Stellen übereinstimmen.
const _kFgChannelId   = 'geofence_service';
const _kFgChannelName = 'Standort-Erkennung (Hintergrund)';
const _kEvChannelId   = 'geofence_events';
const _kEvChannelName = 'Geofence-Ereignisse';

/// Configure the background service. Call once from main() before runApp.
Future<void> configureGeofencingBackground() async {
  // ── Notification-Channels im Hauptisolate anlegen ──────────────────────────
  // Android 8+ verlangt dass Channels existieren BEVOR startForeground()
  // aufgerufen wird. flutter_background_service kann den Channel nicht
  // zuverlässig selbst anlegen, wenn der Service via BootReceiver startet.
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // Foreground-Service-Channel (importance LOW – keine Ton-/Vibrations-Störung)
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      _kFgChannelId,
      _kFgChannelName,
      description: 'Dauerhafter Hintergrundservice für Standort-Geofencing',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ),
  );

  // Ereignis-Channel (importance DEFAULT – erscheint als Popup)
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      _kEvChannelId,
      _kEvChannelName,
      description: 'Benachrichtigungen beim Betreten/Verlassen von Standorten',
      importance: Importance.defaultImportance,
    ),
  );

  // ── Background-Service konfigurieren ──────────────────────────────────────
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      // autoStart: false – Service nur starten wenn Standorte konfiguriert sind.
      // Verhindert den Crash "Bad notification for startForeground" beim
      // Erststart ohne konfigurierte Locations.
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _kFgChannelId,
      initialNotificationTitle: 'Standort-Erkennung aktiv',
      initialNotificationContent: 'GPS wird überwacht …',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

// ── Background isolate entry point ────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final Set<String> inside = {};
  var locations = <Map<String, dynamic>>[];

  // ── Receive commands from main isolate ─────────────────────────────────────

  service.on('setLocations').listen((data) {
    if (data == null) return;
    final incoming = List<Map<String, dynamic>>.from(
      (data['locations'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final newIds = incoming.map((l) => l['id'] as String).toSet();
    inside.removeWhere((id) => !newIds.contains(id));
    locations = incoming;
  });

  service.on('stop').listen((_) => service.stopSelf());

  // ── GPS stream ─────────────────────────────────────────────────────────────

  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    service.stopSelf();
    return;
  }

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    ),
  ).listen((pos) {
    for (final loc in List<Map<String, dynamic>>.from(locations)) {
      final id = loc['id'] as String;
      final dist = _haversine(
        pos.latitude, pos.longitude,
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      final radius = (loc['radiusMeters'] as num).toDouble();
      final wasInside = inside.contains(id);
      final nowInside = dist <= radius;

      if (!wasInside && nowInside) {
        inside.add(id);
        service.invoke('zoneChange', {
          'locationId': id,
          'locationName': loc['name'] as String,
          'employerId': loc['employerId'],
          'entered': true,
        });
        _notify(notifications, id.hashCode,
            'Standort: ${loc['name']}', 'Arbeitszeit jetzt starten?');
      } else if (wasInside && !nowInside) {
        inside.remove(id);
        service.invoke('zoneChange', {
          'locationId': id,
          'locationName': loc['name'] as String,
          'employerId': loc['employerId'],
          'entered': false,
        });
        _notify(notifications, id.hashCode + 1,
            'Standort verlassen: ${loc['name']}', 'Arbeitszeit beenden?');
      }
    }
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _notify(FlutterLocalNotificationsPlugin n, int id, String title, String body) {
  n.show(id, title, body, const NotificationDetails(
    android: AndroidNotificationDetails(
      _kEvChannelId,
      _kEvChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
  ));
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;
