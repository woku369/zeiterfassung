class ActivityLog {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String appName;

  // Phone-call specific (null for app sessions)
  final bool isPhoneCall;
  final String? phoneNumber;
  final int? callType; // 1=eingehend  2=ausgehend  3=verpasst

  const ActivityLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.appName,
    this.isPhoneCall = false,
    this.phoneNumber,
    this.callType,
  });

  Duration get duration => endTime.difference(startTime);
  int get durationMinutes => duration.inMinutes;

  bool get isMissed => isPhoneCall && callType == 3;

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'title': title,
    'app_name': appName,
  };

  factory ActivityLog.fromMap(Map<String, dynamic> m) => ActivityLog(
    id: m['id'] as String,
    startTime: DateTime.parse(m['start_time'] as String),
    endTime: DateTime.parse(m['end_time'] as String),
    title: m['title'] as String,
    appName: m['app_name'] as String,
  );
}
