import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Lazy initialize GoogleSignIn to avoid initialization issues
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: ApiConfig.googleWebClientId,
    );
    return _googleSignInInstance!;
  }

  // Login with email & password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        body: {'email': email, 'password': password},
      );

      // Handle both flat {token, user} and wrapped {data: {token, user}} response
      final data = _extractData(response);

      if (data['token'] != null && data['user'] != null) {
        await _saveAuthData(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
        );
      }

      return data;
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        body: {'name': name, 'email': email, 'password': password},
      );

      final data = _extractData(response);
      if (data['token'] != null && data['user'] != null) {
        await _saveAuthData(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
        );
      }

      return data;
    } catch (e) {
      throw Exception('Registrasi gagal: $e');
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in dibatalkan');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Gagal mendapatkan ID token dari Google. Pastikan SHA-1 sudah dikonfigurasi di Google Console.',
        );
      }

      // Kirim hanya idToken sesuai dokumentasi backend
      final response = await _apiService.post(
        ApiConfig.googleAuth,
        body: {'idToken': idToken},
      );

      final data = _extractData(response);

      if (data['token'] != null && data['user'] != null) {
        await _saveAuthData(
          data['token'] as String,
          data['user'] as Map<String, dynamic>,
        );
      }

      return data;
    } catch (e) {
      throw Exception('Google sign-in gagal: $e');
    }
  }

  /// Ekstrak data dari response — handle flat {token,user} atau wrapped {data:{token,user}}
  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  // Save auth data to local storage
  Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    print('[Auth] Saving auth data...');
    print('[Auth] Token: $token');
    print('[Auth] User data: $userData');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);

    print('[Auth] Creating User from JSON...');
    final user = User.fromJson(userData);
    print('[Auth] User created: ${user.email}');

    await prefs.setString(ApiConfig.userKey, user.toJsonString());
    print('[Auth] Auth data saved successfully');
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  // Get stored user
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(ApiConfig.userKey);

    if (userString != null) {
      return User.fromJsonString(userString);
    }

    return null;
  }

  // Save user to local storage
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.userKey, user.toJsonString());
    print('[Auth] User data updated in storage');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('[Auth] Changing password...');

      // Get current token for authentication
      final token = await getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await _apiService.post(
        ApiConfig.changePassword,
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
        token: token,
      );

      print('[Auth] Password changed successfully');
      return true;
    } catch (e) {
      print('[Auth] Change password error: $e');
      throw Exception(
        'Gagal mengubah password: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userKey);

    // Sign out from Google
    await _googleSignIn.signOut();
  }
}
