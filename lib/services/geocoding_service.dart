import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  // Reverse geocoding: Coordinates → Address
  Future<Map<String, dynamic>?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reverse').replace(
          queryParameters: {
            'format': 'json',
            'lat': latitude.toString(),
            'lon': longitude.toString(),
            'addressdetails': '1',
            'accept-language': 'id',
          },
        ),
        headers: {'User-Agent': 'MajaCraft/1.0'},
      );

      print('[GeocodingService] Reverse geocode: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('[GeocodingService] Error reverse geocoding: $e');
      return null;
    }
  }

  // Geocoding: Address → Coordinates
  Future<Map<String, dynamic>?> geocode(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search').replace(
          queryParameters: {
            'format': 'json',
            'q': address,
            'limit': '1',
            'countrycodes': 'ID',
            'addressdetails': '1',
            'accept-language': 'id',
          },
        ),
        headers: {'User-Agent': 'MajaCraft/1.0'},
      );

      print('[GeocodingService] Geocode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          return results.first;
        }
      }
      return null;
    } catch (e) {
      print('[GeocodingService] Error geocoding: $e');
      return null;
    }
  }

  // Parse address components from Nominatim response
  Map<String, String> parseAddressComponents(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return {};

    return {
      'road': address['road'] ?? '',
      'village':
          address['village'] ?? address['suburb'] ?? address['hamlet'] ?? '',
      'district': address['city_district'] ?? address['district'] ?? '',
      'city': address['city'] ?? address['town'] ?? address['county'] ?? '',
      'province': address['state'] ?? '',
      'postcode': address['postcode'] ?? '',
      'country': address['country'] ?? '',
    };
  }
}
