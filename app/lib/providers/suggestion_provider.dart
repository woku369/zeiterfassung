import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/suggested_entry.dart';
import '../models/activity_log.dart';
import '../models/time_entry.dart';
import '../services/fusion_engine.dart';

class SuggestionProvider extends ChangeNotifier {
  List<SuggestedEntry> _suggestions = [];
  final Set<String> _dismissed = {};
  final Set<String> _accepted = {};
  bool _loaded = false;

  List<SuggestedEntry> get pending {
    if (!_loaded) return [];
    return _suggestions
        .where((s) => !_dismissed.contains(s.id) && !_accepted.contains(s.id))
        .toList();
  }

  List<SuggestedEntry> get adopted {
    if (!_loaded) return [];
    return _suggestions.where((s) => _accepted.contains(s.id)).toList();
  }

  bool get hasPending => pending.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed.addAll(prefs.getStringList(_prefKeyDismissed) ?? []);
    _accepted.addAll(prefs.getStringList(_prefKeyAccepted) ?? []);
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
    _persistDismissed();
    notifyListeners();
  }

  Future<void> accept(String id) async {
    _accepted.add(id);
    await _persistAccepted();
    notifyListeners();
  }

  void clearForDate() {
    _suggestions = [];
    notifyListeners();
  }

  static const _prefKeyDismissed = 'fusion_dismissed_ids';
  static const _prefKeyAccepted  = 'fusion_accepted_ids';

  Future<void> _persistDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    var ids = _dismissed.toList();
    if (ids.length > 500) ids = ids.skip(ids.length - 500).toList();
    await prefs.setStringList(_prefKeyDismissed, ids);
  }

  Future<void> _persistAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    var ids = _accepted.toList();
    if (ids.length > 500) ids = ids.skip(ids.length - 500).toList();
    await prefs.setStringList(_prefKeyAccepted, ids);
  }
}
