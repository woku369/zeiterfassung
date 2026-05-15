import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../models/employer.dart';

/// Berechnet Vertragsäquivalente für die Gurktaler AG.
///
/// Basis: 8 Wochenstunden (Mo–Fr) am Standort Gurk – zuschlagsfrei.
/// Homeoffice ist immer zuschlagsfrei (auch Sa/So/Feiertag/nachts).
/// Sonderarbeitszeiten (Führungen, manuell markiert) erhalten Zuschläge:
///   • Samstag       → Faktor 1.5
///   • Sonntag       → Faktor 2.0
///   • Feiertag      → Faktor 2.0
///   • Werktag       → Faktor 1.0 (kein Zuschlag, gilt als Mehrarbeit)
class SurchargeService {
  static const double _saturdayFactor = 1.5;
  static const double _sundayFactor   = 2.0;
  static const double _holidayFactor  = 2.0;

  /// True wenn dieser Arbeitgeber überhaupt Zuschläge bekommt.
  static bool isSurchargeEmployer(Employer? e) {
    if (e == null) return false;
    return e.name.toLowerCase().contains('gurktaler');
  }

  /// Faktor für einen einzelnen Eintrag. Homeoffice und nicht markierte
  /// Einträge → 1.0. Nur wenn `isSpecialHours` gesetzt ist und der Tag
  /// Sa/So/Feiertag ist, kommt der Zuschlag zum Tragen.
  static double factorFor(TimeEntry entry, {required bool isSurchargeEmployer}) {
    if (!isSurchargeEmployer) return 1.0;
    if (!entry.isSpecialHours) return 1.0;
    if (entry.workType == WorkType.homeoffice) return 1.0;
    return switch (entry.dayType) {
      DayType.saturday => _saturdayFactor,
      DayType.sunday   => _sundayFactor,
      DayType.holiday  => _holidayFactor,
      DayType.workday  => 1.0,
    };
  }

  /// Vertragsäquivalent in Stunden (Ist × Faktor).
  static double equivalentHours(TimeEntry entry,
          {required bool isSurchargeEmployer}) =>
      entry.totalHours * factorFor(entry, isSurchargeEmployer: isSurchargeEmployer);
}
