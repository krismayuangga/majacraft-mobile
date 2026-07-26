import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address.dart';

class AddressService {
  static const String baseUrl = 'https://majacraft.id/api';

  // Get all addresses
  Future<List<Address>> getAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[AddressService] GET /addresses: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List addressList = data['data'] ?? [];
        return addressList.map((json) => Address.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load addresses: ${response.body}');
      }
    } catch (e) {
      print('[AddressService] Error getting addresses: $e');
      rethrow;
    }
  }

  // Create new address
  Future<Address> createAddress(String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      print('[AddressService] POST /addresses: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Address.fromJson(responseData['data'] ?? responseData);
      } else {
        throw Exception('Failed to create address: ${response.body}');
      }
    } catch (e) {
      print('[AddressService] Error creating address: $e');
      rethrow;
    }
  }

  // Update address
  Future<Address> updateAddress(
    String token,
    String addressId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      print(
        '[AddressService] PATCH /addresses/$addressId: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Address.fromJson(responseData['data'] ?? responseData);
      } else {
        throw Exception('Failed to update address: ${response.body}');
      }
    } catch (e) {
      print('[AddressService] Error updating address: $e');
      rethrow;
    }
  }

  // Delete address
  Future<void> deleteAddress(String token, String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        '[AddressService] DELETE /addresses/$addressId: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete address: ${response.body}');
      }
    } catch (e) {
      print('[AddressService] Error deleting address: $e');
      rethrow;
    }
  }

  // Set as default/primary
  Future<Address> setDefaultAddress(String token, String addressId) async {
    return updateAddress(token, addressId, {'isDefault': true});
  }
}
