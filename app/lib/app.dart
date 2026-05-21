import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/employer_provider.dart';
import 'providers/time_entry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/project_provider.dart';
import 'services/geofencing_service.dart';
import 'services/tray_service.dart';
import 'screens/home_screen.dart';
import 'screens/activity_timeline_screen.dart';

class ZeiterfassungApp extends StatefulWidget {
  final MethodChannel navChannel;
  const ZeiterfassungApp({super.key, required this.navChannel});

  @override
  State<ZeiterfassungApp> createState() => _ZeiterfassungAppState();
}

class _ZeiterfassungAppState extends State<ZeiterfassungApp>
    with WindowListener {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      // Must be called AFTER addListener, otherwise the X button still
      // terminates the process because no listener handles the event.
      windowManager.setPreventClose(true);
    }

    widget.navChannel.setMethodCallHandler((call) async {
      if (call.method == 'openTimeline') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ActivityTimelineScreen()),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGeofenceCallback();
      _setupSync();
      _initTray();
    });
  }

  @override
  void dispose() {
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  // ── Window close → minimize to tray ─────────────────────────────────────

  @override
  void onWindowClose() async {
    if (!Platform.isWindows) return;
    final preventClose = await windowManager.isPreventClose();
    if (preventClose) {
      await windowManager.hide();
    }
  }

  // ── Tray-Setup ────────────────────────────────────────────────────────────

  Future<void> _initTray() async {
    if (!Platform.isWindows) return;
    final tp = context.read<TimeEntryProvider>();

    await TrayService.instance.init(
      onClockIn: () {
        // Öffnet das Einstempeln-Sheet über die Home-Route
        // (vereinfacht: App in Vordergrund bringen genügt – User stempelt selbst)
      },
      onClockOut: () {},
      onOpenApp: () {
        windowManager.show();
        windowManager.focus();
      },
      onQuit: () async {
        TrayService.instance.dispose();
        await windowManager.destroy();
      },
    );

    // Tray-Status bei Provider-Änderungen aktualisieren
    tp.addListener(_syncTrayStatus);
    _syncTrayStatus();
  }

  void _syncTrayStatus() {
    if (!Platform.isWindows) return;
    final tp = context.read<TimeEntryProvider>();
    final active = tp.activeEntry;
    final label = active != null
        ? 'Seit ${_hhmm(active.startTime)} · ${active.workType.label}'
        : null;
    TrayService.instance.updateClockedIn(active != null, label: label);
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Sync & Geofencing ─────────────────────────────────────────────────────

  Future<void> _setupSync() async {
    final sp = context.read<SyncProvider>();
    final tp = context.read<TimeEntryProvider>();
    final lp = context.read<LocationProvider>();
    final ep = context.read<EmployerProvider>();
    tp.setSyncTrigger(sp.triggerSync);
    sp.setOnSyncComplete(() async {
      await ep.reload();
      await lp.load();
      await tp.refresh();
      await context.read<ProjectProvider>().load();
    });
    sp.startPeriodicSync();
    await sp.syncNow();
    await lp.load();
    await tp.refresh();
    if (GeofencingService.instance.isTracking) {
      GeofencingService.instance.updateLocations(lp.activeLocations);
    }
    // Auto-start geofencing on fresh install (key never set = null).
    if (Platform.isAndroid && !GeofencingService.instance.isTracking) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('geofencing_active') == null &&
          lp.activeLocations.isNotEmpty) {
        await GeofencingService.instance.startTracking(lp.activeLocations);
      }
    }
  }

  void _setupGeofenceCallback() {
    GeofencingService.instance.onZoneChange = (location, entered) async {
      if (!mounted) return;
      // Switch active employer when entering a zone.
      if (entered && location.employerId != null) {
        final ep = context.read<EmployerProvider>();
        final employers = ep.employers;
        final idx = employers.indexWhere((e) => e.id == location.employerId);
        if (idx != -1) ep.setActive(employers[idx]);
      }
      // The background isolate already wrote the clock-in/out to the DB.
      // Give it a short head-start then refresh the UI.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.read<TimeEntryProvider>().refresh();
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Zeiterfassung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      locale: const Locale('de', 'AT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'AT'),
        Locale('de', 'DE'),
      ],
      home: const HomeScreen(),
    );
  }
}
