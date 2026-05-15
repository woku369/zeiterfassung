import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/suggested_entry.dart';
import '../models/activity_log.dart';
import '../models/time_entry.dart';
import '../services/fusion_engine.dart';

class SuggestionProvider extends ChangeNotifier {
  List<SuggestedEntry> _suggestions = [];
  final Set<String> _dismissed = {};
  bool _loaded = false;

  List<SuggestedEntry> get pending {
    if (!_loaded) return [];
    return _suggestions.where((s) => !_dismissed.contains(s.id)).toList();
  }

  bool get hasPending => pending.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed.addAll(prefs.getStringList(_prefKey) ?? []);
    _loaded = true;
  }

  Future<void> generate(
    DateTime date, {
    required List<ActivityLog> sessions,
    required List<TimeEntry> existingEntries,
    String? activeEmployerId,
  }) async {
    _suggestions = FusionEngine.generate(
      date: date,
      sessions: sessions,
      existingEntries: existingEntries,
      activeEmployerId: activeEmployerId,
    );
    notifyListeners();
  }

  void dismiss(String id) {
    _dismissed.add(id);
    _persist();
    notifyListeners();
  }

  void clearForDate() {
    _suggestions = [];
    notifyListeners();
  }

  static const _prefKey = 'fusion_dismissed_ids';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    // Cap at 500 entries to avoid unbounded growth
    var ids = _dismissed.toList();
    if (ids.length > 500) ids = ids.skip(ids.length - 500).toList();
    await prefs.setStringList(_prefKey, ids);
  }
}
