import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:uuid/uuid.dart';

// ── Geofence-Log ─────────────────────────────────────────────────────────────

const kGeofenceLogFilename = 'geofence_log.txt';
const _kMaxLogLines = 2000;

Future<String> geofenceLogPath() async =>
    p.join(await getDatabasesPath(), kGeofenceLogFilename);

Future<void> _log(String tag, String msg) async {
  try {
    final path = await geofenceLogPath();
    final ts = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');
    final line = '$ts  [$tag]  $msg\n';
    final file = File(path);
    await file.writeAsString(line, mode: FileMode.append, flush: true);
    // Trim to last _kMaxLogLines lines
    final content = await file.readAsString();
    final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
    if (lines.length > _kMaxLogLines) {
      await file.writeAsString(
        '${lines.skip(lines.length - _kMaxLogLines).join('\n')}\n',
      );
    }
  } catch (_) {}
}

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

const _kAutoEntryKey         = 'geofence_auto_entry_id';
const _kAutoEntryEmployerKey = 'geofence_auto_entry_employer_id';
const kTripTrackingKey       = 'trip_tracking_active';
const _kOpenTripKey          = 'trip_open_id';
const _kSpeedStartMs         = 4.2;  // 15 km/h – trip begins
const _kSpeedStopMs          = 1.4;  // 5 km/h  – stop candidate
const _kMinDistKm            = 0.3;  // ignore micro-trips
const kBtTripDevicesKey      = 'bt_trip_devices';   // JSON list of MAC addresses
const _kBtEventKey           = 'bt_trip_event';     // written by BluetoothTripReceiver

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
  final timers = <String, Timer>{}; // locationId → pending clock-out timer
  DateTime? outsideZonesSince = DateTime.now();

  // ── Trip tracking state ────────────────────────────────────────────────────
  String?   _tripId;
  DateTime? _tripStart;
  double?   _tripStartLat, _tripStartLng;
  double?   _tripLastLat,  _tripLastLng;
  double    _tripDistKm = 0;
  Timer?    _tripStopTimer;       // fires when speed drops for >2 min
  bool      _tripActive = false;   // currently in a "moving" phase
  bool      _btTripActive = false; // trip was started by BT connect

  // ── Receive commands from main isolate ─────────────────────────────────────

  service.on('setLocations').listen((data) {
    if (data == null) return;
    final incoming = List<Map<String, dynamic>>.from(
      (data['locations'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final newIds = incoming.map((l) => l['id'] as String).toSet();
    inside.removeWhere((id) => !newIds.contains(id));
    locations = incoming;
    _log('INIT', 'Zonen geladen: ${incoming.map((l) => l['name']).join(', ')}');
  });

  // ── Watchdog: warn if auto-clocked-in but outside all zones for a while ───
  final watchdog = Timer.periodic(const Duration(minutes: 15), (_) async {
    if (inside.isNotEmpty) return;
    if (outsideZonesSince == null) return;
    if (DateTime.now().difference(outsideZonesSince!).inMinutes < 30) return;

    final prefs = await SharedPreferences.getInstance();
    final entryId = prefs.getString(_kAutoEntryKey);
    if (entryId == null) return; // only watch auto-created entries

    try {
      final db = await _openDb();
      final rows = await db.query('time_entries',
          where: 'id = ? AND end_time IS NULL',
          whereArgs: [entryId], limit: 1);
      await db.close();
      if (rows.isEmpty) {
        // Already clocked out manually – clear stale flag.
        await prefs.remove(_kAutoEntryKey);
        await prefs.remove(_kAutoEntryEmployerKey);
        return;
      }
      final start = DateTime.parse(rows.first['start_time'] as String);
      final dur = DateTime.now().difference(start);
      final h = dur.inHours;
      final m = dur.inMinutes.remainder(60);
      _notify(notifications, 994, 'Noch eingestempelt?',
          'Seit ${h}h ${m}m aktiv, aber außerhalb aller Zonen. Ausstempeln vergessen?');
    } catch (_) {}
  });

  service.on('stop').listen((_) {
    watchdog.cancel();
    for (final t in timers.values) t.cancel();
    service.stopSelf();
  });

  // ── GPS stream ─────────────────────────────────────────────────────────────

  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    service.stopSelf();
    return;
  }

  DateTime? _lastGpsLog;

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    ),
  ).listen((pos) async {
    final now = DateTime.now();

    // GPS-Log: höchstens alle 30 s, aber immer wenn Zonen aktiv sind
    if (_lastGpsLog == null ||
        now.difference(_lastGpsLog!).inSeconds >= 30 ||
        locations.isNotEmpty) {
      _lastGpsLog = now;
      final nearbyParts = <String>[];
      for (final loc in locations) {
        final d = _haversine(pos.latitude, pos.longitude,
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble());
        final r = (loc['radiusMeters'] as num).toDouble();
        nearbyParts.add('${loc['name']}=${d.toStringAsFixed(0)}m/${r.toStringAsFixed(0)}m');
      }
      await _log('GPS',
          'lat=${pos.latitude.toStringAsFixed(6)} '
          'lon=${pos.longitude.toStringAsFixed(6)} '
          'acc=${pos.accuracy.toStringAsFixed(0)}m  '
          '${nearbyParts.join('  ')}');
    }

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
        timers[id]?.cancel();
        timers.remove(id);
        await _log('ENTER', '${loc['name']}  dist=${dist.toStringAsFixed(0)}m  radius=${radius.toStringAsFixed(0)}m');
        await _autoClockIn(loc, notifications);
        service.invoke('zoneChange', {
          'locationId': id,
          'locationName': loc['name'] as String,
          'employerId': loc['employerId'],
          'entered': true,
        });
      } else if (wasInside && !nowInside) {
        inside.remove(id);
        await _log('EXIT', '${loc['name']}  dist=${dist.toStringAsFixed(0)}m  Karenz 5 min');
        timers[id]?.cancel();
        timers[id] = Timer(const Duration(minutes: 5), () async {
          timers.remove(id);
          if (!inside.contains(id)) {
            await _log('CLOCK-OUT', 'Auto nach Karenz  ${loc['name']}');
            await _autoClockOut(notifications);
            service.invoke('zoneChange', {
              'locationId': id,
              'locationName': loc['name'] as String,
              'employerId': loc['employerId'],
              'entered': false,
            });
          } else {
            await _log('CANCEL', 'Karenz abgebrochen – wieder in Zone ${loc['name']}');
          }
        });
        _notify(notifications, id.hashCode + 1,
            'Zone verlassen: ${loc['name'] as String}',
            'Ausstempeln in 5 Minuten sofern du nicht zurückkehrst.');
      }
    }
    if (inside.isNotEmpty) {
      outsideZonesSince = null;
    } else if (outsideZonesSince == null) {
      outsideZonesSince = DateTime.now();
    }

    // ── Trip tracking ──────────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();

    // ── Bluetooth trigger (written by BluetoothTripReceiver.kt) ───────────
    final btEvent = prefs.getString(_kBtEventKey);
    if (btEvent != null && (prefs.getBool(kTripTrackingKey) ?? false)) {
      await prefs.remove(_kBtEventKey); // consume only when tracking enabled
      if (btEvent.startsWith('connect:') && !_tripActive) {
        final mac = btEvent.substring(8);
        _tripId       = const Uuid().v4();
        _tripStart    = now;
        _tripStartLat = pos.latitude;
        _tripStartLng = pos.longitude;
        _tripLastLat  = pos.latitude;
        _tripLastLng  = pos.longitude;
        _tripDistKm   = 0;
        _tripActive   = true;
        _btTripActive = true;
        _tripStopTimer?.cancel();
        _tripStopTimer = null;
        await prefs.setString(_kOpenTripKey, _tripId!);
        await _log('TRIP-START', 'BT-Connect $mac  id=$_tripId');
        await _insertOpenTrip(_tripId!, _tripStart!, pos.latitude, pos.longitude);
      } else if (btEvent.startsWith('disconnect:') && _tripActive && _btTripActive) {
        final mac = btEvent.substring(11);
        _btTripActive = false;
        _tripActive   = false;
        _tripStopTimer?.cancel();
        _tripStopTimer = null;
        // Use startLat/Lng as fallback if no GPS tick yet after connect
        final endLat = _tripLastLat ?? _tripStartLat ?? pos.latitude;
        final endLng = _tripLastLng ?? _tripStartLng ?? pos.longitude;
        await _log('TRIP-END', 'BT-Disconnect $mac  id=$_tripId  dist=${_tripDistKm.toStringAsFixed(2)}km');
        await _finalizeTrip(
          id: _tripId!, endLat: endLat, endLng: endLng,
          distKm: _tripDistKm, notifications: notifications);
        _tripId = null; _tripDistKm = 0;
        await prefs.remove(_kOpenTripKey);
      }
    }

    if (prefs.getBool(kTripTrackingKey) ?? false) {
      final speed = pos.speed >= 0 ? pos.speed : 0.0; // m/s; -1 = unavailable

      if (!_tripActive && speed >= _kSpeedStartMs) {
        // Start a new trip
        _tripId       = const Uuid().v4();
        _tripStart    = now;
        _tripStartLat = pos.latitude;
        _tripStartLng = pos.longitude;
        _tripLastLat  = pos.latitude;
        _tripLastLng  = pos.longitude;
        _tripDistKm   = 0;
        _tripActive   = true;
        _btTripActive = false;
        _tripStopTimer?.cancel();
        _tripStopTimer = null;
        await prefs.setString(_kOpenTripKey, _tripId!);
        await _log('TRIP-START', 'id=$_tripId  speed=${(speed * 3.6).toStringAsFixed(1)}km/h');
        // Persist skeleton so UI can show "Fahrt läuft"
        await _insertOpenTrip(
            _tripId!, _tripStart!, pos.latitude, pos.longitude);
      } else if (_tripActive) {
        // Accumulate distance
        if (_tripLastLat != null && _tripLastLng != null) {
          final d = _haversine(
              _tripLastLat!, _tripLastLng!, pos.latitude, pos.longitude);
          if (d < 0.5) _tripDistKm += d; // ignore GPS jumps > 500 m
        }
        _tripLastLat = pos.latitude;
        _tripLastLng = pos.longitude;

        if (speed < _kSpeedStopMs) {
          // Start stop-candidate timer if not already running
          _tripStopTimer ??= Timer(const Duration(minutes: 2), () async {
            _tripStopTimer = null;
            if (!_tripActive) return;
            _tripActive   = false;
            _btTripActive = false;
            await _finalizeTrip(
              id:       _tripId!,
              endLat:   _tripLastLat!,
              endLng:   _tripLastLng!,
              distKm:   _tripDistKm,
              notifications: notifications,
            );
            _tripId = null; _tripDistKm = 0;
            await prefs.remove(_kOpenTripKey);
          });
        } else {
          // Still moving – cancel any pending stop
          _tripStopTimer?.cancel();
          _tripStopTimer = null;
        }
      }
    } else if (_tripActive) {
      // Trip tracking was disabled mid-trip – finalize cleanly
      _tripActive   = false;
      _btTripActive = false;
      _tripStopTimer?.cancel();
      _tripStopTimer = null;
      if (_tripId != null && _tripLastLat != null && _tripLastLng != null) {
        await _finalizeTrip(
          id: _tripId!, endLat: _tripLastLat!, endLng: _tripLastLng!,
          distKm: _tripDistKm, notifications: notifications);
      }
      await prefs.remove(_kOpenTripKey);
    }
  });
}

// ── Auto clock-in / clock-out ─────────────────────────────────────────────────

Future<void> _autoClockIn(
    Map<String, dynamic> loc, FlutterLocalNotificationsPlugin n) async {
  final prefs = await SharedPreferences.getInstance();

  final now        = DateTime.now();
  final id         = const Uuid().v4();
  final workType   = loc['workType'] as String? ?? 'offsite';
  final employerId = loc['employerId'] as String?;
  final name       = loc['name'] as String;

  try {
    final db = await _openDb();
    // Skip if already clocked in (manually or via geofencing) – the user
    // explicitly does not want overlapping entries.
    final active = await db.query('time_entries',
        where: 'end_time IS NULL', limit: 1);
    if (active.isNotEmpty) {
      await db.close();
      await _log('SKIP', 'Bereits eingestempelt – $name übersprungen');
      _notify(n, 995, 'Bei $name angekommen',
          'Bereits eingestempelt – Geofencing übersprungen.');
      return;
    }

    await db.insert('time_entries', {
      'id':            id,
      'employer_id':   employerId,
      'date':          DateTime(now.year, now.month, now.day).toIso8601String(),
      'start_time':    now.toIso8601String(),
      'end_time':      null,
      'work_type':     workType,
      'day_type':      'workday',
      'note':          'Auto · $name',
      'break_minutes': 0,
      'distance_km':   null,
      'travel_minutes':null,
      'created_at':    now.toIso8601String(),
    });
    await db.close();

    await prefs.setString(_kAutoEntryKey, id);
    if (employerId != null) {
      await prefs.setString(_kAutoEntryEmployerKey, employerId);
    }
    await _log('CLOCK-IN', 'OK  $name  workType=$workType  employerId=$employerId');
    _notify(n, 997, 'Eingestempelt: $name',
        'Automatisch gestartet. Tippen, um Notiz/Tätigkeit zu ergänzen.');
  } catch (e) {
    await _log('ERROR', 'Clock-in fehlgeschlagen: $e');
    _notify(n, 998, 'Auto-Einstempeln fehlgeschlagen', e.toString());
  }
}

Future<void> _autoClockOut(FlutterLocalNotificationsPlugin n) async {
  final prefs   = await SharedPreferences.getInstance();
  final entryId = prefs.getString(_kAutoEntryKey);
  if (entryId == null) return;

  final now = DateTime.now();
  try {
    final db = await _openDb();
    // Gesetzliche Pause: ab 5h automatisch 30 Min., außer Homeoffice.
    final rows = await db.query('time_entries',
        columns: ['start_time', 'work_type', 'break_minutes'],
        where: 'id = ? AND end_time IS NULL',
        whereArgs: [entryId], limit: 1);
    int breakMinutes = 0;
    if (rows.isNotEmpty) {
      final existing = rows.first;
      final start = DateTime.parse(existing['start_time'] as String);
      final durationMinutes = now.difference(start).inMinutes;
      final workType = existing['work_type'] as String;
      final alreadySet = (existing['break_minutes'] as int?) ?? 0;
      if (alreadySet == 0 && durationMinutes >= 300 && workType != 'homeoffice') {
        breakMinutes = 30;
        await _log('PAUSE', 'Auto 30 Min. eingetragen (${durationMinutes}min Arbeitszeit)');
      }
    }
    await db.update(
      'time_entries',
      {'end_time': now.toIso8601String(), 'break_minutes': breakMinutes},
      where: 'id = ? AND end_time IS NULL',
      whereArgs: [entryId],
    );
    await db.close();
    final breakNote = breakMinutes > 0 ? ' · 30 Min. Pause eingetragen' : '';
    _notify(n, 996, 'Ausgestempelt',
        'Geofencing hat automatisch gestoppt.$breakNote Zum Bearbeiten App öffnen.');
  } catch (_) {
    // Ignore – entry stays open, user clocks out manually.
  } finally {
    await prefs.remove(_kAutoEntryKey);
    await prefs.remove(_kAutoEntryEmployerKey);
  }
}

Future<Database> _openDb() async {
  final path = p.join(await getDatabasesPath(), 'zeiterfassung.db');
  final db = await openDatabase(path, singleInstance: false);
  await db.rawQuery('PRAGMA journal_mode=WAL');
  return db;
}

Future<void> _insertOpenTrip(
    String id, DateTime start, double lat, double lng) async {
  try {
    final db = await _openDb();
    await db.insert('trips', {
      'id':         id,
      'start_time': start.toIso8601String(),
      'end_time':   null,
      'start_lat':  lat,
      'start_lng':  lng,
      'distance_km': 0.0,
      'created_at': start.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.close();
  } catch (e) {
    await _log('TRIP-ERROR', 'insertOpenTrip: $e');
  }
}

Future<void> _finalizeTrip({
  required String id,
  required double endLat,
  required double endLng,
  required double distKm,
  required FlutterLocalNotificationsPlugin notifications,
}) async {
  if (distKm < _kMinDistKm) {
    // Too short – delete skeleton
    try {
      final db = await _openDb();
      await db.delete('trips', where: 'id = ?', whereArgs: [id]);
      await db.close();
    } catch (_) {}
    await _log('TRIP-SKIP', 'Zu kurz: ${distKm.toStringAsFixed(2)} km');
    return;
  }
  final now = DateTime.now();
  try {
    final db = await _openDb();
    await db.update('trips', {
      'end_time':   now.toIso8601String(),
      'end_lat':    endLat,
      'end_lng':    endLng,
      'distance_km': distKm,
    }, where: 'id = ?', whereArgs: [id]);
    await db.close();
    await _log('TRIP-END', 'id=$id  dist=${distKm.toStringAsFixed(2)}km');
    _notify(notifications, 991,
        'Fahrt beendet: ${distKm.toStringAsFixed(1)} km',
        'Im Fahrtenbuch dokumentiert. Tippen zum Übernehmen.');
  } catch (e) {
    await _log('TRIP-ERROR', 'finalizeTrip: $e');
  }
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
