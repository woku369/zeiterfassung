import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/employer_provider.dart';
import 'providers/time_entry_provider.dart';
import 'providers/sync_provider.dart';
import 'services/geofencing_service.dart';
import 'screens/home_screen.dart';
import 'screens/activity_timeline_screen.dart';

class ZeiterfassungApp extends StatefulWidget {
  final MethodChannel navChannel;
  const ZeiterfassungApp({super.key, required this.navChannel});

  @override
  State<ZeiterfassungApp> createState() => _ZeiterfassungAppState();
}

class _ZeiterfassungAppState extends State<ZeiterfassungApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
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
    });
  }

  void _setupSync() {
    final sp = context.read<SyncProvider>();
    final tp = context.read<TimeEntryProvider>();
    tp.setSyncTrigger(sp.triggerSync);
    sp.startPeriodicSync();
    sp.syncNow(); // startup sync (fire-and-forget)
  }

  void _setupGeofenceCallback() {
    GeofencingService.instance.onZoneChange = (location, entered) {
      if (!entered || location.employerId == null) return;
      final ep = context.read<EmployerProvider>();
      final employers = ep.employers;
      final idx = employers.indexWhere((e) => e.id == location.employerId);
      if (idx != -1) ep.setActive(employers[idx]);
    };
  }

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
