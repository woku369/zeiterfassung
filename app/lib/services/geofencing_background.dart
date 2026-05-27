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
import 'backup_service.dart';
import 'holiday_service.dart';

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
const _kInsideZonesKey       = 'geofence_inside_zones'; // persisted CSV of zone IDs
const kTripTrackingKey       = 'trip_tracking_active';
const _kOpenTripKey          = 'trip_open_id';
const _kSpeedStartMs         = 4.2;  // 15 km/h – trip begins
const _kSpeedStopMs          = 1.4;  // 5 km/h  – stop candidate
const _kMinDistKm            = 0.3;  // ignore micro-trips
const kBtTripDevicesKey      = 'bt_trip_devices';   // JSON list of MAC addresses
const _kBtEventKey           = 'bt_trip_event';     // written by BluetoothTripReceiver
// Exit-Bestätigung: Zone erst als verlassen werten nach N aufeinanderfolgenden
// Messungen außerhalb. Ein einzelner schlechter GPS-Fix löst keinen Exit aus.
const _kExitConfirmRequired  = 4;    // × 20 s Intervall = ~80 s Mindest-Exitzeit
// Hysterese zusätzlich zum Radius: erst ab dieser Distanz zählt eine Messung
// als "außen" für den Bestätigungs-Zähler.
const _kExitBufferM          = 80.0;
// GPS-Fixes mit schlechterer Genauigkeit werden für den Zonen-Check ignoriert.
// 150m: akzeptiert typisches Cell/WiFi-Positioning (100m), filtert nur sehr
// schlechte Fixes heraus (>150m). Alle Zonen sind ≥150m Radius, Fehler <150m
// ändert weit entfernte Zonen-Zugehörigkeit nicht.
const _kMaxAccuracyM         = 150.0;

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
  // Zählt aufeinanderfolgende "außen"-Messungen pro Zone.
  // Exit wird erst ausgelöst wenn der Zähler _kExitConfirmRequired erreicht.
  final Map<String, int> exitConfirm = {};
  // Restore inside-set from the previous service run so that a MIUI-induced
  // restart does not re-fire zone-entry events for zones the user was already in.
  {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kInsideZonesKey) ?? '';
    if (saved.isNotEmpty) inside.addAll(saved.split(','));
  }
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
  bool      _tripActive = false;  // currently in a "moving" phase
  bool      _btTripActive = false; // trip was started by BT connect
  DateTime? _lastMovementTime;    // last GPS tick with speed >= stop threshold
  // Live flag updated via 'setTripTracking' message. SharedPreferences cache in
  // the background isolate is stale after the main isolate writes to it, so we
  // maintain this local copy and update it on service start + on message.
  bool _tripTrackingEnabled = false;
  {
    final prefs = await SharedPreferences.getInstance();
    _tripTrackingEnabled = prefs.getBool(kTripTrackingKey) ?? false;
  }

  // Dynamic GPS accuracy: medium (balanced power) normally, high during trip.
  StreamSubscription<Position>? _posSub;
  Timer? _keepAlive;
  late void Function(Position) _posHandler;

  void _restartGps(LocationAccuracy acc) {
    _posSub?.cancel();
    final bool highPrecision = acc == LocationAccuracy.high;
    _posSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: acc,
        // During trip: 10 m / 5 s – tight tracking.
        // Idle: distanceFilter=0 so Android sees continuous demand and does not
        // suspend GPS hardware during Doze. intervalDuration=30 s limits wakeups.
        distanceFilter: highPrecision ? 10 : 0,
        intervalDuration: highPrecision
            ? const Duration(seconds: 5)
            : const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Standorterfassung aktiv',
          notificationTitle: 'Zeiterfassung',
          enableWakeLock: true,
        ),
      ),
    ).listen(
      _posHandler,
      onError: (Object e) async {
        await _log('GPS-ERROR', 'Stream-Fehler: $e – Neustart in 10 s');
        await Future<void>.delayed(const Duration(seconds: 10));
        _restartGps(acc);
      },
      cancelOnError: false,
    );
  }

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

  service.on('setTripTracking').listen((data) {
    if (data == null) return;
    _tripTrackingEnabled = (data['enabled'] as bool?) ?? false;
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
      late final List<Map<String, Object?>> rows;
      try {
        rows = await db.query('time_entries',
            where: 'id = ? AND end_time IS NULL',
            whereArgs: [entryId], limit: 1);
      } finally {
        await db.close();
      }
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

  // Keep-alive: update foreground notification every minute so MIUI/HyperOS
  // treats the service as actively working and doesn't suspend the isolate.
  // Without this, the 2-min trip-stop timer may be delayed by hours on MIUI.
  _keepAlive = Timer.periodic(const Duration(minutes: 1), (_) {
    if (service is AndroidServiceInstance) {
      final msg = _tripActive
          ? 'Fahrt läuft · ${_tripDistKm.toStringAsFixed(1)} km'
          : inside.isNotEmpty
              ? 'Zone aktiv · Stempel läuft'
              : 'Bereit';
      (service as AndroidServiceInstance).setForegroundNotificationInfo(
          title: 'Standort-Erkennung aktiv', content: msg);
    }
  });

  // Scheduled-Backup-Timer: prüft jede Minute ob ein geplantes Backup fällig ist.
  final backupTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
    await _checkScheduledBackup();
  });

  service.on('stop').listen((_) {
    watchdog.cancel();
    _keepAlive?.cancel();
    backupTimer.cancel();
    _posSub?.cancel();
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
  // Previous GPS position + time, used to compute speed when pos.speed == -1
  double?   _prevLat, _prevLng;
  DateTime? _prevTime;

  _posHandler = (pos) async {
    final now = DateTime.now();

    // Effective speed in m/s: prefer GPS Doppler, fall back to position-derived.
    // Fallback only activates when pos.speed == -1 (GPS explicitly unavailable).
    // Do NOT fall back when pos.speed == 0 — that is a valid "stationary" reading
    // and using position-derived speed there would produce false triggers from
    // GPS jitter on a stationary device.
    double effectiveSpeed = pos.speed >= 0 ? pos.speed : 0.0;
    if (pos.speed < 0 && _prevLat != null && _prevTime != null) {
      final dtSec = now.difference(_prevTime!).inMilliseconds / 1000.0;
      if (dtSec >= 2 && dtSec < 30) {
        effectiveSpeed =
            _haversine(_prevLat!, _prevLng!, pos.latitude, pos.longitude) / dtSec;
      }
    }
    // ── Service-Gap-Detektion ─────────────────────────────────────────────
    // Wenn der Service >30 Min. inaktiv war (HyperOS-Suspension) und sich
    // die Position um >1 km verändert hat, Nutzer benachrichtigen.
    if (_prevTime != null && _prevLat != null && _prevLng != null) {
      final gapMin = now.difference(_prevTime!).inMinutes;
      if (gapMin > 30) {
        final gapDist = _haversine(
            _prevLat!, _prevLng!, pos.latitude, pos.longitude);
        await _log('SERVICE-GAP',
            'Inaktiv ${gapMin}min · ${(gapDist / 1000).toStringAsFixed(1)}km Positionsänderung');
        if (gapDist > 1000 && _tripTrackingEnabled) {
          _notify(notifications, 993, 'Fahrt evtl. nicht erfasst',
              'Service war ${gapMin} Min. inaktiv. Fahrtenbuch und Einstempelstatus prüfen.');
        }
      }
    }
    _prevLat  = pos.latitude;
    _prevLng  = pos.longitude;
    _prevTime = now;

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
          'acc=${pos.accuracy.toStringAsFixed(0)}m '
          'spd=${(effectiveSpeed * 3.6).toStringAsFixed(1)}km/h  '
          '${nearbyParts.join('  ')}');
    }

    // Skip poor-accuracy fixes for zone checks only (trip tracking still uses them).
    // Adaptive threshold: max(radius × 0.5, _kMaxAccuracyM) per zone, checked below.
    final accuracyOk = pos.accuracy <= _kMaxAccuracyM;
    if (!accuracyOk) {
      await _log('GPS-SKIP',
          'Accuracy ${pos.accuracy.toStringAsFixed(0)}m > ${_kMaxAccuracyM.toStringAsFixed(0)}m – Zonen-Check übersprungen');
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

      // Bei schlechter Accuracy: Status einfrieren, Zähler nicht verändern.
      if (!accuracyOk) continue;

      // "Außen" erst wenn dist > radius + Puffer (Hysterese).
      final outsideThreshold = radius + _kExitBufferM;
      final measuredOutside = dist > outsideThreshold;
      final measuredInside  = dist <= radius;

      // Eintritt: sofort bei erster gültigen "innen"-Messung.
      if (!wasInside && measuredInside) {
        exitConfirm.remove(id);
        inside.add(id);

        // Prüfen ob für diese Zone gerade ein Karenz-Timer läuft (User kehrt
        // zur selben Zone zurück bevor der Timer ausgelöst hat).
        final returningFromCarenz = timers.containsKey(id);
        timers[id]?.cancel();
        timers.remove(id);

        // Alle anderen Zonen-States bereinigen: Karenz-Timer abbrechen,
        // andere Zonen aus 'inside' entfernen (exitConfirm-Zähler auch).
        if (timers.isNotEmpty) {
          for (final t in timers.values) t.cancel();
          timers.clear();
        }
        final otherInside = inside.where((zid) => zid != id).toList();
        for (final zid in otherInside) {
          inside.remove(zid);
          exitConfirm.remove(zid);
        }
        if (otherInside.isNotEmpty) {
          await _log('ZONE-SWITCH',
              '${otherInside.length} andere Zone(n) verlassen beim Eintritt in ${loc['name']}');
        }
        (await SharedPreferences.getInstance())
            .setString(_kInsideZonesKey, inside.join(','));

        if (returningFromCarenz && otherInside.isEmpty) {
          // User ist innerhalb der Karenz-Zeit in dieselbe Zone zurückgekehrt.
          // Bestehenden Eintrag behalten – kein Clock-out / Clock-in nötig.
          await _log('CANCEL',
              'Karenz abgebrochen – zurück in Zone ${loc['name']}');
        } else {
          // Normaler Eintritt (oder Zonenwechsel): alten Eintrag schließen,
          // neuen öffnen. _autoClockOut ist no-op wenn kein Eintrag offen ist.
          await _autoClockOut(notifications);
          await _log('ENTER', '${loc['name']}  dist=${dist.toStringAsFixed(0)}m  radius=${radius.toStringAsFixed(0)}m');
          final clockedIn = await _autoClockIn(loc, notifications);
          if (!clockedIn) {
            // Clock-in wurde übersprungen (manueller Eintrag blockiert).
            // Zone NICHT als 'inside' merken – verhindert falsche EXIT-Notifications
            // wenn der Service nach Stunden neu startet und die Zone noch in den
            // SharedPreferences steht.
            inside.remove(id);
            (await SharedPreferences.getInstance())
                .setString(_kInsideZonesKey, inside.join(','));
          } else {
            service.invoke('zoneChange', {
              'locationId': id,
              'locationName': loc['name'] as String,
              'employerId': loc['employerId'],
              'entered': true,
            });
          }
        }
        continue;
      }

      // Austritt: erst nach _kExitConfirmRequired aufeinanderfolgenden "außen"-Messungen.
      if (wasInside) {
        if (measuredOutside) {
          exitConfirm[id] = (exitConfirm[id] ?? 0) + 1;
          await _log('EXIT-CANDIDATE',
              '${loc['name']}  dist=${dist.toStringAsFixed(0)}m  confirm=${exitConfirm[id]}/$_kExitConfirmRequired');
          if (exitConfirm[id]! < _kExitConfirmRequired) {
            continue; // noch nicht genug Bestätigungen
          }
          exitConfirm.remove(id);
        } else {
          // Noch innerhalb (oder zwischen radius und outsideThreshold) → Zähler zurücksetzen
          exitConfirm.remove(id);
          continue;
        }

        // Bestätigter Exit – nur erreichbar wenn wasInside=true und Zähler voll.
        inside.remove(id);
        (await SharedPreferences.getInstance())
            .setString(_kInsideZonesKey, inside.join(','));
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
      // wasInside=false, !measuredInside → nichts tun (außen bleibt außen)
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
    if (btEvent != null && _tripTrackingEnabled) {
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
        _restartGps(LocationAccuracy.high);
        _tripStopTimer?.cancel();
        _tripStopTimer = null;
        await prefs.setString(_kOpenTripKey, _tripId!);
        await _log('TRIP-START', 'BT-Connect $mac  id=$_tripId');
        await _insertOpenTrip(_tripId!, _tripStart!, pos.latitude, pos.longitude);
      } else if (btEvent.startsWith('disconnect:') && _tripActive && _btTripActive) {
        final mac = btEvent.substring(11);
        _btTripActive = false;
        _tripActive   = false;
        _restartGps(LocationAccuracy.medium);
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

    if (_tripTrackingEnabled) {

      if (!_tripActive && effectiveSpeed >= _kSpeedStartMs) {
        // Start a new trip
        _tripId           = const Uuid().v4();
        _tripStart        = now;
        _tripStartLat     = pos.latitude;
        _tripStartLng     = pos.longitude;
        _tripLastLat      = pos.latitude;
        _tripLastLng      = pos.longitude;
        _tripDistKm       = 0;
        _lastMovementTime = now;
        _tripActive       = true;
        _btTripActive     = false;
        _restartGps(LocationAccuracy.high);
        _tripStopTimer?.cancel();
        _tripStopTimer = null;
        await prefs.setString(_kOpenTripKey, _tripId!);
        await _log('TRIP-START', 'id=$_tripId  speed=${(effectiveSpeed * 3.6).toStringAsFixed(1)}km/h');
        // Persist skeleton so UI can show "Fahrt läuft"
        await _insertOpenTrip(
            _tripId!, _tripStart!, pos.latitude, pos.longitude);
      } else if (_tripActive) {
        // Accumulate distance
        if (_tripLastLat != null && _tripLastLng != null) {
          final d = _haversine(
              _tripLastLat!, _tripLastLng!, pos.latitude, pos.longitude);
          if (d < 500) _tripDistKm += d / 1000; // d is in metres; skip jumps > 500 m
        }
        _tripLastLat = pos.latitude;
        _tripLastLng = pos.longitude;

        if (effectiveSpeed < _kSpeedStopMs) {
          // Start stop-candidate timer if not already running.
          // Capture last-movement snapshot for the timer closure: if MIUI suspends
          // the isolate, the timer fires late and DateTime.now() would produce a
          // wrong (inflated) end time. Using the snapshot keeps the end time correct.
          final capturedLastMovement = _lastMovementTime;
          _tripStopTimer ??= Timer(const Duration(minutes: 2), () async {
            _tripStopTimer = null;
            if (!_tripActive) return;
            _tripActive   = false;
            _btTripActive = false;
            _restartGps(LocationAccuracy.medium);
            // If the service was suspended between the last movement and now
            // (gap > 15 min), use lastMovement + 2 min as the real end time.
            final realEnd = capturedLastMovement != null &&
                DateTime.now().difference(capturedLastMovement).inMinutes > 15
                ? capturedLastMovement.add(const Duration(minutes: 2))
                : DateTime.now();
            await _finalizeTrip(
              id:       _tripId!,
              endLat:   _tripLastLat!,
              endLng:   _tripLastLng!,
              distKm:   _tripDistKm,
              endTime:  realEnd,
              notifications: notifications,
            );
            _tripId = null; _tripDistKm = 0;
            await prefs.remove(_kOpenTripKey);
          });
        } else {
          // Still moving – cancel any pending stop and update last movement time.
          _tripStopTimer?.cancel();
          _tripStopTimer = null;
          _lastMovementTime = now;
        }
      }
    } else if (_tripActive) {
      // Trip tracking was disabled mid-trip – finalize cleanly
      _tripActive   = false;
      _btTripActive = false;
      _restartGps(LocationAccuracy.medium);
      _tripStopTimer?.cancel();
      _tripStopTimer = null;
      if (_tripId != null && _tripLastLat != null && _tripLastLng != null) {
        await _finalizeTrip(
          id: _tripId!, endLat: _tripLastLat!, endLng: _tripLastLng!,
          distKm: _tripDistKm, notifications: notifications);
      }
      await prefs.remove(_kOpenTripKey);
    }
  };

  _restartGps(LocationAccuracy.medium);
}

// ── Auto clock-in / clock-out ─────────────────────────────────────────────────

Future<bool> _autoClockIn(
    Map<String, dynamic> loc, FlutterLocalNotificationsPlugin n) async {
  final prefs = await SharedPreferences.getInstance();

  final now        = DateTime.now();
  final id         = const Uuid().v4();
  final workType   = loc['workType'] as String? ?? 'offsite';
  final employerId = loc['employerId'] as String?;
  final name       = loc['name'] as String;

  try {
    final db = await _openDb();
    try {
      // Skip if already clocked in manually. Close stale geofence auto-entries
      // (identified by note prefix 'Auto · ') that were not properly cleaned up
      // when _kAutoEntryKey was lost due to a service restart.
      final active = await db.query('time_entries',
          columns: ['id', 'note', 'start_time', 'work_type'],
          where: "end_time IS NULL AND work_type NOT IN ('vacation','sick','compensatoryLeave')",
          limit: 1);
      if (active.isNotEmpty) {
        final existingId    = active.first['id']         as String;
        final existingNote  = active.first['note']       as String? ?? '';
        final existingStart = active.first['start_time'] as String? ?? '?';
        final existingType  = active.first['work_type']  as String? ?? '?';
        if (existingNote.startsWith('Auto · ')) {
          // Stale auto-entry – close it so the new zone gets a fresh clock-in.
          await db.update(
            'time_entries',
            {'end_time': now.toIso8601String(), 'is_synced': 0},
            where: 'id = ? AND end_time IS NULL',
            whereArgs: [existingId],
          );
          await prefs.remove(_kAutoEntryKey);
          await _log('AUTO-CLOSE-STALE',
              'Veralteten Auto-Eintrag geschlossen: $existingId  start=$existingStart  note=$existingNote');
        } else {
          await _log('SKIP',
              'Manueller Eintrag blockiert $name – id=$existingId  start=$existingStart  type=$existingType  note=$existingNote');
          _notify(n, 995, 'Bei $name angekommen',
              'Bereits eingestempelt – Geofencing übersprungen.');
          return false;
        }
      }

      final dayType = HolidayService.instance.isHoliday(now)
          ? 'holiday'
          : now.weekday == 6
              ? 'saturday'
              : now.weekday == 7
                  ? 'sunday'
                  : 'workday';

      await db.insert('time_entries', {
        'id':            id,
        'employer_id':   employerId,
        'date':          '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}',
        'start_time':    now.toIso8601String(),
        'end_time':      null,
        'work_type':     workType,
        'day_type':      dayType,
        'note':          'Auto · $name',
        'break_minutes': 0,
        'distance_km':   (loc['defaultKm'] as num?)?.toDouble(),
        'created_at':    now.toIso8601String(),
      });
    } finally {
      await db.close();
    }

    await prefs.setString(_kAutoEntryKey, id);
    if (employerId != null) {
      await prefs.setString(_kAutoEntryEmployerKey, employerId);
    }
    await _log('CLOCK-IN', 'OK  $name  workType=$workType  employerId=$employerId');
    _notify(n, 997, 'Eingestempelt: $name',
        'Automatisch gestartet. Tippen, um Notiz/Tätigkeit zu ergänzen.');
    return true;
  } catch (e) {
    await _log('ERROR', 'Clock-in fehlgeschlagen: $e');
    _notify(n, 998, 'Auto-Einstempeln fehlgeschlagen', e.toString());
    return false;
  }
}

Future<void> _autoClockOut(FlutterLocalNotificationsPlugin n) async {
  final prefs   = await SharedPreferences.getInstance();
  final entryId = prefs.getString(_kAutoEntryKey);
  if (entryId == null) return;

  final now = DateTime.now();
  var breakMinutes = 0;
  try {
    final db = await _openDb();
    try {
      // Gesetzliche Pause: ab 6h automatisch 30 Min. (§ 11 AZG), außer Homeoffice.
      final rows = await db.query('time_entries',
          columns: ['start_time', 'work_type', 'break_minutes'],
          where: 'id = ? AND end_time IS NULL',
          whereArgs: [entryId], limit: 1);
      if (rows.isNotEmpty) {
        final existing = rows.first;
        final start = DateTime.parse(existing['start_time'] as String);
        final durationMinutes = now.difference(start).inMinutes;
        final workType = existing['work_type'] as String;
        final alreadySet = (existing['break_minutes'] as int?) ?? 0;
        if (alreadySet == 0 && durationMinutes >= 360 && workType != 'homeoffice') {
          breakMinutes = 30;
          await _log('PAUSE', 'Auto 30 Min. eingetragen (${durationMinutes}min Arbeitszeit)');
        }
      }
      await db.update(
        'time_entries',
        {'end_time': now.toIso8601String(), 'break_minutes': breakMinutes, 'is_synced': 0},
        where: 'id = ? AND end_time IS NULL',
        whereArgs: [entryId],
      );
    } finally {
      await db.close();
    }
    // Key erst nach erfolgreichem DB-Update entfernen. Schlägt der Update
    // fehl (Exception oben), bleibt der Key erhalten und der nächste Aufruf
    // kann den Eintrag erneut versuchen zu schließen.
    await prefs.remove(_kAutoEntryKey);
    await prefs.remove(_kAutoEntryEmployerKey);
    final breakNote = breakMinutes > 0 ? ' · 30 Min. Pause eingetragen' : '';
    _notify(n, 996, 'Ausgestempelt',
        'Geofencing hat automatisch gestoppt.$breakNote Zum Bearbeiten App öffnen.');
  } catch (e) {
    await _log('ERROR', 'Auto-Ausstempeln fehlgeschlagen: $e');
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
    try {
      await db.insert('trips', {
        'id':         id,
        'start_time': start.toIso8601String(),
        'end_time':   null,
        'start_lat':  lat,
        'start_lng':  lng,
        'distance_km': 0.0,
        'created_at': start.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } finally {
      await db.close();
    }
  } catch (e) {
    await _log('TRIP-ERROR', 'insertOpenTrip: $e');
  }
}

Future<void> _finalizeTrip({
  required String id,
  required double endLat,
  required double endLng,
  required double distKm,
  DateTime? endTime,
  required FlutterLocalNotificationsPlugin notifications,
}) async {
  if (distKm < _kMinDistKm) {
    // Too short – delete skeleton
    try {
      final db = await _openDb();
      int breakMinutes = 0;
      try {
        await db.delete('trips', where: 'id = ?', whereArgs: [id]);
      } finally {
        await db.close();
      }
    } catch (_) {}
    await _log('TRIP-SKIP', 'Zu kurz: ${distKm.toStringAsFixed(2)} km');
    return;
  }
  final end = endTime ?? DateTime.now();
  try {
    final db = await _openDb();
    try {
      await db.update('trips', {
        'end_time':   end.toIso8601String(),
        'end_lat':    endLat,
        'end_lng':    endLng,
        'distance_km': distKm,
      }, where: 'id = ?', whereArgs: [id]);
    } finally {
      await db.close();
    }
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

// ── Geplante Backups ──────────────────────────────────────────────────────────

/// Prüft ob ein tägliches, monatliches oder jährliches Backup fällig ist
/// und führt es bei Bedarf durch. Wird einmal pro Minute aufgerufen.
Future<void> _checkScheduledBackup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final nasUrl = prefs.getString('global_nas_url') ?? '';
    if (nasUrl.isEmpty) return; // kein NAS konfiguriert

    final apiKey = prefs.getString('global_nas_api_key');
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;

    // ── Jährliches Backup (ab 01:00, 1. des Monats, Monat == WJ-Startmonat)
    // Catch-up: läuft auch wenn 01:00 verpasst wurde (h >= 1 statt h == 1).
    if (h >= 1 && now.day == 1) {
      final fiscalMonth = await _getFiscalYearStartMonth();
      if (now.month == fiscalMonth) {
        final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final lastYearly = prefs.getString('backup_last_yearly') ?? '';
        if (lastYearly != ym) {
          final lastAttemptStr = prefs.getString('backup_last_yearly_attempt') ?? '';
          final lastAttempt = DateTime.tryParse(lastAttemptStr);
          final cooldownOk = lastAttempt == null ||
              now.difference(lastAttempt).inMinutes >= 30;
          if (cooldownOk) {
            await prefs.setString('backup_last_yearly_attempt', now.toIso8601String());
            final (ok, err) = await BackupService.instance.scheduledNasBackup(
              nasUrl: nasUrl,
              apiKey: apiKey,
              type: 'yearly',
            );
            if (ok) {
              await prefs.setString('backup_last_yearly', ym);
              await prefs.remove('backup_last_yearly_attempt');
              await _log('BACKUP', 'Jährliches Backup erfolgreich: $ym');
            } else {
              await _log('BACKUP', 'Jährliches Backup fehlgeschlagen ($err) – nächster Versuch in 30 min');
            }
          }
        }
      }
    }

    // ── Monatliches Backup (ab 01:30, 1. des Monats)
    // Catch-up: läuft auch wenn 01:30 verpasst wurde.
    if ((h > 1 || (h == 1 && m >= 29)) && now.day == 1) {
      final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastMonthly = prefs.getString('backup_last_monthly') ?? '';
      if (lastMonthly != ym) {
        final lastAttemptStr = prefs.getString('backup_last_monthly_attempt') ?? '';
        final lastAttempt = DateTime.tryParse(lastAttemptStr);
        final cooldownOk = lastAttempt == null ||
            now.difference(lastAttempt).inMinutes >= 30;
        if (cooldownOk) {
          await prefs.setString('backup_last_monthly_attempt', now.toIso8601String());
          final (ok, err) = await BackupService.instance.scheduledNasBackup(
            nasUrl: nasUrl,
            apiKey: apiKey,
            type: 'monthly',
          );
          if (ok) {
            await prefs.setString('backup_last_monthly', ym);
            await prefs.remove('backup_last_monthly_attempt');
            await _log('BACKUP', 'Monatliches Backup erfolgreich: $ym');
          } else {
            await _log('BACKUP', 'Monatliches Backup fehlgeschlagen ($err) – nächster Versuch in 30 min');
          }
        }
      }
    }

    // Tägliches Backup läuft jetzt via SyncProvider._runDailyBackupIfNeeded()
    // nach jedem erfolgreichen Sync – zuverlässiger als Zeitfenster hier.
  } catch (e) {
    await _log('BACKUP-ERROR', e.toString());
  }
}

/// Liest den Wirtschaftsjahr-Startmonat aus der DB (erster Arbeitgeber, Default 4).
Future<int> _getFiscalYearStartMonth() async {
  try {
    final db = await _openDb();
    try {
      final rows = await db.query('employers',
          columns: ['fiscal_year_start_month'],
          where: 'deleted_at IS NULL',
          limit: 1);
      if (rows.isNotEmpty) {
        return (rows.first['fiscal_year_start_month'] as int?) ?? 4;
      }
    } finally {
      await db.close();
    }
  } catch (_) {}
  return 4; // Default: April
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
