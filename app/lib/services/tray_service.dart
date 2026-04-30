import 'package:flutter/foundation.dart';

// Windows tray integration.
// Requires: flutter create --platforms=windows . (run once in /app)
// Then add to windows/runner/main.cpp:
//   #include <tray_manager/tray_manager.h>
//   #include <window_manager/window_manager.h>
// and call WindowManager::GetInstance()->WaitUntilReadyToShow() before RunLoop.

/// On non-Windows or when the Windows platform folder hasn't been generated,
/// this service is a no-op.  Once the Windows runner is present and the
/// packages are available, remove the [_isSupported] guard.
class TrayService {
  TrayService._();
  static final TrayService instance = TrayService._();

  // tray_manager and window_manager are only functional on Windows.
  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool _initialized = false;

  /// Call from main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> init({
    required VoidCallback onClockIn,
    required VoidCallback onClockOut,
    required VoidCallback onOpenApp,
    required VoidCallback onQuit,
  }) async {
    if (!_isSupported || _initialized) return;
    _initialized = true;

    // Dynamic dispatch – avoids compile errors when windows/ folder is absent.
    // Replace with direct tray_manager calls once the platform folder exists.
    try {
      await _initTray(
        onClockIn: onClockIn,
        onClockOut: onClockOut,
        onOpenApp: onOpenApp,
        onQuit: onQuit,
      );
    } catch (e) {
      debugPrint('TrayService: init failed – $e');
    }
  }

  Future<void> _initTray({
    required VoidCallback onClockIn,
    required VoidCallback onClockOut,
    required VoidCallback onOpenApp,
    required VoidCallback onQuit,
  }) async {
    // ── Uncomment and adjust once windows/ folder exists ──────────────────
    //
    // await windowManager.ensureInitialized();
    // await windowManager.setPreventClose(true);
    // await windowManager.setSkipTaskbar(false);
    //
    // await trayManager.setIcon('assets/tray_icon.ico');
    // await trayManager.setContextMenu(Menu(items: [
    //   MenuItem(key: 'clock_in',  label: 'Arbeitszeit starten'),
    //   MenuItem(key: 'clock_out', label: 'Arbeitszeit beenden'),
    //   MenuItem.separator(),
    //   MenuItem(key: 'open',      label: 'App öffnen'),
    //   MenuItem.separator(),
    //   MenuItem(key: 'quit',      label: 'Beenden'),
    // ]));
    // trayManager.addListener(_TrayListener(
    //   onClockIn: onClockIn,
    //   onClockOut: onClockOut,
    //   onOpenApp: onOpenApp,
    //   onQuit: onQuit,
    // ));
    //
    // ──────────────────────────────────────────────────────────────────────
    debugPrint('TrayService: Windows platform folder not yet generated. '
        'Run: flutter create --platforms=windows . inside /app');
  }

  /// Updates the tray tooltip to show current tracking state.
  Future<void> setStatus(String status) async {
    if (!_isSupported || !_initialized) return;
    // await trayManager.setToolTip('Zeiterfassung – $status');
  }

  void dispose() {
    if (!_isSupported || !_initialized) return;
    // trayManager.removeListener(...);
    _initialized = false;
  }
}
