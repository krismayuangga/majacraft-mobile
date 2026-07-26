import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/region.dart';

class RegionService {
  static const String baseUrl =
      'https://www.emsifa.com/api-wilayah-indonesia/api';

  // Get all provinces
  Future<List<Province>> getProvinces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/provinces.json'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      print('[RegionService] Error getting provinces: $e');
      rethrow;
    }
  }

  // Get regencies (cities) by province ID
  Future<List<Regency>> getRegencies(String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/regencies/$provinceId.json'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Regency.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load regencies');
      }
    } catch (e) {
      print('[RegionService] Error getting regencies: $e');
      rethrow;
    }
  }

  // Get districts by regency ID
  Future<List<District>> getDistricts(String regencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/districts/$regencyId.json'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => District.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load districts');
      }
    } catch (e) {
      print('[RegionService] Error getting districts: $e');
      rethrow;
    }
  }

  // Get villages by district ID
  Future<List<Village>> getVillages(String districtId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/villages/$districtId.json'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Village.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load villages');
      }
    } catch (e) {
      print('[RegionService] Error getting villages: $e');
      rethrow;
    }
  }
}
