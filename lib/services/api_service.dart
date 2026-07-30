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

  // Multipart file upload — returns URL string from response data.url
  Future<String?> uploadFile(
    String endpoint,
    dynamic file, {
    String fieldName = 'file',
    String? token,
    Map<String, String>? extraFields,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (extraFields != null) request.fields.addAll(extraFields);
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      return data?['url']?.toString();
    } catch (_) {
      return null;
    }
  }

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
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        // Handle case where response is a Map with success field
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == true) {
            return decoded;
          }

          // If status code is success, return the decoded response
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return decoded;
          }

          // If status code is error, throw exception
          throw Exception(
            decoded['message'] ?? decoded['error'] ?? 'Request failed',
          );
        }

        // Handle string responses
        if (decoded is String) {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return {'success': true, 'message': decoded};
          }
          throw Exception(decoded);
        }

        // Handle other types
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': decoded};
        }
        throw Exception(decoded.toString());
      } catch (e) {
        // If JSON decode fails and status is success, return success
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true};
        }
        // If JSON decode fails and status is error, throw with body or error
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Invalid JSON response: $e');
      }
    }

    // Empty body handling
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true};
    }

    throw Exception('Request failed with status ${response.statusCode}');
  }
}
