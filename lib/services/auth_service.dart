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
      print('[Auth] Logging in with: $email');
      final response = await _apiService.post(
        ApiConfig.login,
        body: {'email': email, 'password': password},
      );

      print('[Auth] Login response: $response');
      print('[Auth] Token: ${response['token']}');
      print('[Auth] User data: ${response['user']}');

      // Save token and user data
      if (response['token'] != null && response['user'] != null) {
        await _saveAuthData(response['token'], response['user']);
      }

      return response;
    } catch (e) {
      print('[Auth] Login error: $e');
      throw Exception('Login failed: $e');
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

      // Save token and user data
      if (response['token'] != null && response['user'] != null) {
        await _saveAuthData(response['token'], response['user']);
      }

      return response;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send to backend
      final response = await _apiService.post(
        ApiConfig.googleAuth,
        body: {
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
        },
      );

      // Save token and user data
      if (response['token'] != null && response['user'] != null) {
        await _saveAuthData(response['token'], response['user']);
      }

      return response;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
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
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        token: token,
      );

      print('[Auth] Password changed successfully');
      return true;
    } catch (e) {
      print('[Auth] Change password error: $e');
      throw Exception('Gagal mengubah password: ${e.toString().replaceAll('Exception: ', '')}');
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
