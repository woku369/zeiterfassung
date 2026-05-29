import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../models/employer.dart';

/// Berechnet Vertragsäquivalente für die Gurktaler AG.
///
/// Homeoffice ist immer zuschlagsfrei.
/// Alle anderen Arbeitsarten erhalten automatisch Zuschläge nach Wochentag:
///   • Samstag vor 13:00  → 1.0 (zuschlagsfrei)
///   • Samstag ab 13:00   → 1.5 (50 % Zuschlag)
///   • Sonntag            → 2.0 (100 % Zuschlag)
///   • Feiertag           → 2.0 (100 % Zuschlag)
///   • Werktag            → 1.0 (kein Zuschlag)
class SurchargeService {
  static const double _saturdayFactor = 1.5;
  static const double _sundayFactor   = 2.0;
  static const double _holidayFactor  = 2.0;
  static const int    _saturdayCutoff = 13;

  /// True wenn dieser Arbeitgeber überhaupt Zuschläge bekommt.
  static bool isSurchargeEmployer(Employer? e) {
    if (e == null) return false;
    return e.name.toLowerCase().contains('gurktaler');
  }

  /// Maximaler Faktor für einen Eintrag (für Anzeige / Jahresauswertung).
  static double factorFor(TimeEntry entry, {required bool isSurchargeEmployer}) {
    if (!isSurchargeEmployer) return 1.0;
    if (entry.workType == WorkType.homeoffice) return 1.0;
    return switch (entry.dayType) {
      DayType.saturday => entry.endTime != null &&
              entry.endTime!.hour >= _saturdayCutoff
          ? _saturdayFactor
          : 1.0,
      DayType.sunday   => _sundayFactor,
      DayType.holiday  => _holidayFactor,
      DayType.workday  => 1.0,
    };
  }

  /// Vertragsäquivalent in Stunden mit zeitabhängiger Samstags-Aufteilung.
  static double equivalentHours(TimeEntry entry,
      {required bool isSurchargeEmployer}) {
    if (!isSurchargeEmployer) return entry.totalHours;
    if (entry.workType == WorkType.homeoffice) return entry.totalHours;
    if (entry.dayType != DayType.saturday) {
      return entry.totalHours *
          switch (entry.dayType) {
            DayType.sunday  => _sundayFactor,
            DayType.holiday => _holidayFactor,
            _               => 1.0,
          };
    }
    // Samstag: zeitabhängige Aufteilung an 13:00 Uhr
    final end = entry.endTime;
    if (end == null) return entry.totalHours;
    final start = entry.startTime;
    final cutoff = DateTime(start.year, start.month, start.day, _saturdayCutoff);
    if (!end.isAfter(cutoff)) return entry.totalHours;
    if (!start.isBefore(cutoff)) return entry.totalHours * _saturdayFactor;
    final grossMin  = end.difference(start).inMinutes;
    final beforeMin = cutoff.difference(start).inMinutes;
    final fracBefore = beforeMin / grossMin;
    return entry.totalHours * (fracBefore * 1.0 + (1.0 - fracBefore) * _saturdayFactor);
  }
}
