import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // HTTP Headers
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = _getHeaders(token: token);

      print('[API] GET $url');
      print('[API] Headers: $headers');

      final response = await http.get(url, headers: headers);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = _getHeaders(token: token);
      
      print('[API] POST $url');
      print('[API] Headers: $headers');
      print('[API] Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.patch(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.delete(
        url,
        headers: _getHeaders(token: token),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('[API] Status: ${response.statusCode}');
    print('[API] Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        final decoded = jsonDecode(response.body);
        print('[API] Decoded: $decoded');

        // Handle case where response is a Map
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        // Handle other types (shouldn't happen for success)
        return {'data': decoded};
      } catch (e) {
        print('[API] JSON decode error: $e');
        throw Exception('Invalid JSON response: $e');
      }
    } else {
      // Handle error response
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);

          // If decoded is a String (plain error message)
          if (decoded is String) {
            throw Exception(decoded);
          }

          // If decoded is a Map
          if (decoded is Map<String, dynamic>) {
            throw Exception(
              decoded['message'] ?? decoded['error'] ?? 'Request failed',
            );
          }

          throw Exception(decoded.toString());
        } else {
          throw Exception('Request failed with status ${response.statusCode}');
        }
      } catch (e) {
        // If JSON decode fails, use raw body
        if (response.body.isNotEmpty) {
          throw Exception(response.body);
        }
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }
}
