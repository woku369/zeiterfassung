import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService implements TrayListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  bool _initialized = false;
  bool _isClockedIn = false;

  VoidCallback? _onClockIn;
  VoidCallback? _onClockOut;
  VoidCallback? _onOpenApp;
  VoidCallback? _onQuit;

  Future<void> init({
    required VoidCallback onClockIn,
    required VoidCallback onClockOut,
    required VoidCallback onOpenApp,
    required VoidCallback onQuit,
  }) async {
    if (!Platform.isWindows) return;
    if (_initialized) return;
    _initialized = true;

    _onClockIn  = onClockIn;
    _onClockOut = onClockOut;
    _onOpenApp  = onOpenApp;
    _onQuit     = onQuit;

    trayManager.addListener(this);

    try {
      await trayManager.setIcon('assets/tray_icon.ico');
    } catch (_) {
      // Icon nicht gefunden – Tray funktioniert trotzdem
    }
    await trayManager.setToolTip('Zeiterfassung');
    await _rebuildMenu();
  }

  // Wird von app.dart aufgerufen wenn sich der Eingestempelt-Status ändert.
  Future<void> updateClockedIn(bool isClockedIn, {String? label}) async {
    if (!Platform.isWindows || !_initialized) return;
    _isClockedIn = isClockedIn;
    final tooltip = label != null
        ? 'Zeiterfassung · $label'
        : 'Zeiterfassung';
    await trayManager.setToolTip(tooltip);
    await _rebuildMenu();
  }

  Future<void> _rebuildMenu() async {
    final menu = Menu(items: [
      MenuItem(key: 'open',  label: 'Zeiterfassung öffnen'),
      MenuItem.separator(),
      if (_isClockedIn)
        MenuItem(key: 'clock_out', label: 'Ausstempeln')
      else
        MenuItem(key: 'clock_in',  label: 'Einstempeln'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Beenden'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  // ── TrayListener ──────────────────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) windowManager.show();
    _onOpenApp?.call();
  }

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'open':
        if (Platform.isWindows) windowManager.show();
        _onOpenApp?.call();
      case 'clock_in':
        if (Platform.isWindows) windowManager.show();
        _onClockIn?.call();
      case 'clock_out':
        if (Platform.isWindows) windowManager.show();
        _onClockOut?.call();
      case 'quit':
        _onQuit?.call();
        if (Platform.isWindows) windowManager.destroy();
    }
  }

  @override void onTrayIconMouseUp() {}
  @override void onTrayIconRightMouseDown() {}
  @override void onTrayIconRightMouseUp() {}

  void dispose() {
    if (!Platform.isWindows) return;
    trayManager.removeListener(this);
    _initialized = false;
  }
}
