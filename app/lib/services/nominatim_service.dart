import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  static const _ua = 'Zeiterfassung/1.17 (contact: private use)';

  /// Reverse-geocode a coordinate to a human-readable address.
  /// Returns a short address (road + city) or null on failure.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=de&zoom=16',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return data['display_name'] as String?;
      // Build "Straße HNr, Ort"
      final road = addr['road'] as String?;
      final nr   = addr['house_number'] as String?;
      final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality']) as String?;
      final parts = [
        if (road != null) '${road}${nr != null ? ' $nr' : ''}',
        if (city != null) city,
      ];
      return parts.isNotEmpty ? parts.join(', ') : data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
