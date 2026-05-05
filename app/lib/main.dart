import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'providers/employer_provider.dart';
import 'providers/time_entry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/suggestion_provider.dart';
import 'database/database_helper.dart';
import 'services/geofencing_service.dart';
import 'services/geofencing_background.dart';
import 'services/tray_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  }

  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    await configureGeofencingBackground();
  }
  await GeofencingService.instance.init();

  final activityProvider = ActivityProvider();
  await activityProvider.init();

  final syncProvider = SyncProvider();
  await syncProvider.init();

  final suggestionProvider = SuggestionProvider();
  await suggestionProvider.init();

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
      ],
      child: ZeiterfassungApp(navChannel: navChannel),
    ),
  );

  // Tray wird nach runApp() in app.dart verdrahtet (braucht Provider-Zugriff).
  // TrayService.init() ist kein-op auf Android.
}
