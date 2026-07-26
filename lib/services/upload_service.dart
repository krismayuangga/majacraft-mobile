import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class UploadService {
  static const String baseUrl = 'https://majacraft.id';

  /// Upload image to server
  /// Returns the URL path of uploaded file
  Future<String> uploadImage(
    File imageFile,
    String folder,
    String token,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add folder field
      request.fields['folder'] = folder;

      // Determine mime type
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else {
        mimeType = 'image/jpeg'; // default
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('[UploadService] Uploading to $uri, folder: $folder');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[UploadService] Status: ${response.statusCode}');
      print('[UploadService] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']?['url'] != null) {
          return data['data']['url'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('[UploadService] Error: $e');
      rethrow;
    }
  }
}
