import 'dart:convert';
import 'package:http/http.dart' as http;

class TmAppointment {
  final String id;
  final String title;
  final String type;
  final String status;
  final DateTime? startDate;
  final int participantCount;
  final String? group;

  const TmAppointment({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.startDate,
    required this.participantCount,
    this.group,
  });

  factory TmAppointment.fromJson(Map<String, dynamic> j) {
    final dateStr = j['startDate'] as String? ?? j['start'] as String?;
    return TmAppointment(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      type: j['type'] as String? ?? '',
      status: j['status'] as String? ?? '',
      startDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
      participantCount: (j['participantCount'] as num?)?.toInt() ?? 0,
      group: j['group'] as String?,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'führung': return 'Führung';
      case 'vor-ort': return 'Vor-Ort';
      case 'event':   return 'Event';
      case 'außerhalb': return 'Außerhalb';
      default: return type;
    }
  }
}

class TerminMeisterService {
  TerminMeisterService._();
  static final instance = TerminMeisterService._();

  /// Fetches appointments for [month] (format: "YYYY-MM") from the TM NAS API.
  /// Returns empty list on any error – caller treats TM as optional.
  Future<List<TmAppointment>> fetchMonth(
    String baseUrl,
    String month, {
    String? apiKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/appointments?month=$month');
    final headers = <String, String>{};
    if (apiKey != null && apiKey.isNotEmpty) headers['x-api-key'] = apiKey;
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final raw = jsonDecode(response.body);
      final list = raw is List ? raw : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(TmAppointment.fromJson)
          .where((a) => a.status == 'abgeschlossen')
          .toList();
    } catch (_) {
      return [];
    }
  }
}
