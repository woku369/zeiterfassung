import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'providers/employer_provider.dart';
import 'providers/time_entry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/suggestion_provider.dart';
import 'providers/project_provider.dart';
import 'providers/trip_provider.dart';
import 'database/database_helper.dart';
import 'services/geofencing_service.dart';
import 'services/geofencing_background.dart';
import 'services/tray_service.dart';
import 'package:window_manager/window_manager.dart';

// ── Single-Instance-Guard (Windows) ──────────────────────────────────────────

@Native<IntPtr Function(Uint32, Int32, Pointer<Utf16>)>(
    symbol: 'CreateMutexW', isLeaf: true)
external int _createMutex(int attr, int initialOwner, Pointer<Utf16> name);

@Native<Uint32 Function()>(symbol: 'GetLastError', isLeaf: true)
external int _getLastError();

const _errorAlreadyExists = 183;

/// Returns false if another instance is already running.
bool _acquireSingleInstanceMutex() {
  if (!Platform.isWindows) return true;
  final name = 'ZeiterfassungSingleInstance'.toNativeUtf16();
  try {
    _createMutex(0, 0, name);
    return _getLastError() != _errorAlreadyExists;
  } finally {
    calloc.free(name);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!_acquireSingleInstanceMutex()) {
    // Zweite Instanz – sofort beenden, kein Fenster öffnen.
    exit(0);
  }

  // sqflite auf Desktop (Windows/Linux/macOS) benötigt FFI-Initialisierung.
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await DatabaseHelper.instance.database;

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(420, 780),
      minimumSize: Size(360, 600),
      center: true,
      title: 'Zeiterfassung',
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
    // Note: setPreventClose(true) is called in app.dart after the
    // WindowListener is registered – the order matters, otherwise the
    // close-event has no handler and the window closes anyway.
  }

  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    await configureGeofencingBackground();
  }
  await GeofencingService.instance.init();

  final activityProvider = ActivityProvider();
  await activityProvider.init();

  final syncProvider = SyncProvider();
  await syncProvider.init();
  syncProvider.setActivityProvider(activityProvider);

  final suggestionProvider = SuggestionProvider();
  await suggestionProvider.init();

  final projectProvider = ProjectProvider();
  await projectProvider.ensureGurktalerProjects();

  // Navigation channel: QS Tile → open timeline
  const navChannel = MethodChannel('zeiterfassung/navigation');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployerProvider()..load()),
        // TimeEntryProvider reacts to active employer changes automatically.
        ChangeNotifierProxyProvider<EmployerProvider, TimeEntryProvider>(
          create: (_) => TimeEntryProvider(),
          update: (_, emp, prev) => prev!..setActiveEmployer(emp.active?.id),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()..load()),
        ChangeNotifierProvider.value(value: activityProvider),
        ChangeNotifierProvider.value(value: syncProvider),
        ChangeNotifierProvider.value(value: suggestionProvider),
        ChangeNotifierProvider.value(value: projectProvider),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: ZeiterfassungApp(navChannel: navChannel),
    ),
  );

  // Tray wird nach runApp() in app.dart verdrahtet (braucht Provider-Zugriff).
  // TrayService.init() ist kein-op auf Android.
}
