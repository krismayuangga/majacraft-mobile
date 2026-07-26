import 'dart:convert';
import 'package:http/http.dart' as http;

class PostalCodeResult {
  final String code;
  final String village;
  final String district;
  final String regency;
  final String province;
  final double latitude;
  final double longitude;
  final String? elevation;
  final String? timezone;
  final double? distance;

  PostalCodeResult({
    required this.code,
    required this.village,
    required this.district,
    required this.regency,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.timezone,
    this.distance,
  });

  factory PostalCodeResult.fromJson(Map<String, dynamic> json) {
    return PostalCodeResult(
      code: json['code'].toString(),
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      regency: json['regency'] ?? '',
      province: json['province'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      elevation: json['elevation']?.toString(),
      timezone: json['timezone'],
      distance: json['distance']?.toDouble(),
    );
  }
}

class PostalCodeService {
  static const String _baseUrl = 'https://kodepos.vercel.app';

  /// Search postal code by place name (village, district, regency, or province)
  Future<List<PostalCodeResult>?> searchByPlace(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query}),
      );

      print('[PostalCodeService] Search by place: $query - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['statusCode'] == 200 && data['data'] != null) {
          final List<dynamic> results = data['data'];
          
          if (results.isEmpty) {
            print('[PostalCodeService] No results found for: $query');
            return null;
          }

          return results.map((item) => PostalCodeResult.fromJson(item)).toList();
        }
      }

      return null;
    } catch (e) {
      print('[PostalCodeService] Error searching by place: $e');
      return null;
    }
  }

  /// Detect postal code by coordinates (latitude, longitude)
  Future<PostalCodeResult?> detectByCoordinates(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/detect').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );

      print('[PostalCodeService] Detect by coordinates: ($latitude, $longitude) - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['statusCode'] == 200 && data['data'] != null) {
          return PostalCodeResult.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('[PostalCodeService] Error detecting by coordinates: $e');
      return null;
    }
  }

  /// Find matching region ID from name (case-insensitive, handles common variations)
  String? findMatchingId<T>(
    String targetName,
    List<T> items,
    String Function(T) getName,
    String Function(T) getId,
  ) {
    if (targetName.isEmpty || items.isEmpty) return null;

    final target = _normalizeText(targetName);

    // 1. Exact match
    for (var item in items) {
      if (_normalizeText(getName(item)) == target) {
        return getId(item);
      }
    }

    // 2. Contains match
    for (var item in items) {
      final name = _normalizeText(getName(item));
      if (name.contains(target) || target.contains(name)) {
        return getId(item);
      }
    }

    // 3. Fuzzy match (remove common prefixes/suffixes)
    final cleanTarget = _cleanRegionName(target);
    for (var item in items) {
      final cleanName = _cleanRegionName(_normalizeText(getName(item)));
      if (cleanName == cleanTarget || cleanName.contains(cleanTarget) || cleanTarget.contains(cleanName)) {
        return getId(item);
      }
    }

    return null;
  }

  String _normalizeText(String text) {
    return text.toLowerCase()
      .replaceAll('kabupaten', 'kab')
      .replaceAll('kota', '')
      .trim();
  }

  String _cleanRegionName(String text) {
    return text
      .replaceAll('kab.', '')
      .replaceAll('kab', '')
      .replaceAll('kota', '')
      .replaceAll('.', '')
      .trim();
  }
}
