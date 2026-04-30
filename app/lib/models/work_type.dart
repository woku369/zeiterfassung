enum WorkType {
  homeoffice('Homeoffice', 'home'),
  phoneCall('Telefonat', 'phone'),
  offsite('Außer-Haus-Termin', 'place'),
  travel('Fahrt', 'directions_car'),
  office('Büro', 'business'),
  other('Sonstiges', 'work'),
  vacation('Urlaubstag', 'beach_access'),
  sick('Krankenstandstag', 'sick'),
  compensatoryLeave('Zeitausgleich', 'event_available');

  const WorkType(this.label, this.iconName);
  final String label;
  final String iconName;

  bool get isAbsence =>
      this == WorkType.vacation ||
      this == WorkType.sick ||
      this == WorkType.compensatoryLeave;

  static WorkType fromString(String value) {
    return WorkType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkType.other,
    );
  }
}

enum DayType {
  workday('Werktag'),
  saturday('Samstag'),
  sunday('Sonntag'),
  holiday('Feiertag');

  const DayType(this.label);
  final String label;

  static DayType fromString(String value) {
    return DayType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DayType.workday,
    );
  }
}
