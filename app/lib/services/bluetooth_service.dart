import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple Bluetooth helper – reads paired devices via Android method channel
/// and manages the watchlist stored in SharedPreferences.
///
/// Paired-device discovery uses a MethodChannel defined in MainActivity.kt.
class BluetoothTripService {
  static const _watchlistKey = 'bt_trip_devices';

  // ── Watchlist persistence ────────────────────────────────────────────────

  static Future<List<String>> loadWatchlist() async {
    if (!Platform.isAndroid) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_watchlistKey) ?? '[]';
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> saveWatchlist(List<String> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_watchlistKey, jsonEncode(addresses));
  }
}
