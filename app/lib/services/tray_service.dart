// Windows Tray-Widget – vorbereitet, noch nicht aktiv.
//
// Zum Aktivieren:
//   1. In pubspec.yaml auskommentieren:
//        tray_manager: ^0.2.3
//        window_manager: ^0.3.9
//   2. NuGet.exe installieren (winget install NuGet.NuGet)
//   3. Unten auskommentierte Blöcke einschalten
//   4. flutter build windows

import 'package:flutter/foundation.dart';

class TrayService {
  TrayService._();
  static final TrayService instance = TrayService._();

  bool _initialized = false;

  Future<void> init({
    required VoidCallback onClockIn,
    required VoidCallback onClockOut,
    required VoidCallback onOpenApp,
    required VoidCallback onQuit,
  }) async {
    if (_initialized) return;
    _initialized = true;
    // tray_manager / window_manager hier einsetzen sobald Pakete aktiv sind.
    debugPrint('TrayService: bereit für Aktivierung (siehe Kommentar oben)');
  }

  Future<void> setStatus(String status) async {}

  void dispose() {
    _initialized = false;
  }
}
