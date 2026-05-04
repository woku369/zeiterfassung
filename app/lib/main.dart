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
import 'database/database_helper.dart';
import 'services/geofencing_service.dart';
import 'services/geofencing_background.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite auf Desktop (Windows/Linux/macOS) benötigt FFI-Initialisierung.
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await DatabaseHelper.instance.database;
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    await configureGeofencingBackground();
  }
  await GeofencingService.instance.init();

  final activityProvider = ActivityProvider();
  await activityProvider.init();

  final syncProvider = SyncProvider();
  await syncProvider.init();

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
        ChangeNotifierProxyProvider<EmployerProvider, SyncProvider>(
          create: (_) => syncProvider,
          update: (_, emp, prev) => prev!..updateEmployers(emp.employers),
        ),
      ],
      child: ZeiterfassungApp(navChannel: navChannel),
    ),
  );

  // Windows tray – no-op until flutter create --platforms=windows is run.
  await TrayService.instance.init(
    onClockIn: () {},
    onClockOut: () {},
    onOpenApp: () {},
    onQuit: () {},
  );
}
