class Employer {
  final String id;
  final String name;
  final double weeklyHours;
  final int fiscalYearStartMonth;
  final int vacationDaysPerYear;
  final String? nasUrl;
  final String? nasApiKey;
  final String updatedAt;
  final String? deletedAt;

  Employer({
    required this.id,
    required this.name,
    this.weeklyHours = 40.0,
    this.fiscalYearStartMonth = 4,
    this.vacationDaysPerYear = 25,
    this.nasUrl,
    this.nasApiKey,
    String? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Employer copyWith({
    String? id,
    String? name,
    double? weeklyHours,
    int? fiscalYearStartMonth,
    int? vacationDaysPerYear,
    String? nasUrl,
    String? nasApiKey,
  }) =>
      Employer(
        id: id ?? this.id,
        name: name ?? this.name,
        weeklyHours: weeklyHours ?? this.weeklyHours,
        fiscalYearStartMonth: fiscalYearStartMonth ?? this.fiscalYearStartMonth,
        vacationDaysPerYear: vacationDaysPerYear ?? this.vacationDaysPerYear,
        nasUrl: nasUrl ?? this.nasUrl,
        nasApiKey: nasApiKey ?? this.nasApiKey,
        updatedAt: DateTime.now().toIso8601String(),
        deletedAt: deletedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weekly_hours': weeklyHours,
        'fiscal_year_start_month': fiscalYearStartMonth,
        'vacation_days_per_year': vacationDaysPerYear,
        'nas_url': nasUrl,
        'nas_api_key': nasApiKey,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory Employer.fromMap(Map<String, dynamic> m) => Employer(
        id: m['id'] as String,
        name: m['name'] as String,
        weeklyHours: (m['weekly_hours'] as num?)?.toDouble() ?? 40.0,
        fiscalYearStartMonth: m['fiscal_year_start_month'] as int? ?? 4,
        vacationDaysPerYear: m['vacation_days_per_year'] as int? ?? 25,
        nasUrl: m['nas_url'] as String?,
        nasApiKey: m['nas_api_key'] as String?,
        updatedAt: m['updated_at'] as String?,
        deletedAt: m['deleted_at'] as String?,
      );

  Map<String, dynamic> toJson() => toMap();
  factory Employer.fromJson(Map<String, dynamic> json) => Employer.fromMap(json);

  /// Start date of the fiscal year that contains [date].
  DateTime fiscalYearStart(DateTime date) {
    final y = date.month >= fiscalYearStartMonth
        ? date.year
        : date.year - 1;
    return DateTime(y, fiscalYearStartMonth);
  }

  /// End date (exclusive) of the fiscal year that contains [date].
  DateTime fiscalYearEnd(DateTime date) {
    final start = fiscalYearStart(date);
    return DateTime(start.year + 1, fiscalYearStartMonth);
  }

  /// Human-readable label, e.g. "WJ 2024/25".
  String fiscalYearLabel(DateTime date) {
    final start = fiscalYearStart(date);
    final endYear = (start.year + 1) % 100;
    return 'WJ ${start.year}/${endYear.toString().padLeft(2, '0')}';
  }
}
