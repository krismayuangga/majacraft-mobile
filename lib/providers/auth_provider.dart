import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    print('[AuthProvider] Initializing...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _authService.getToken();
      _user = await _authService.getUser();
      print('[AuthProvider] Session restored. User: ${_user?.email}');
      if (_token != null)
        _registerFCMToken(_token!); // re-register on app start
    } catch (e) {
      print('[AuthProvider] No saved session: $e');
      // No saved session is OK, user will need to login
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with email & password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      _token = response['token'];
      _user = User.fromJson(response['user']);
      _registerFCMToken(_token!); // non-blocking

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Daftarkan FCM token ke backend setelah login
  Future<void> _registerFCMToken(String authToken) async {
    try {
      final fcm = FCMService();
      final fcmToken = fcm.fcmToken ?? await fcm.getLocalFCMToken();
      if (fcmToken != null) {
        await fcm.registerTokenWithBackend(fcmToken, authToken);
        print('[AuthProvider] FCM token registered');
      }
    } catch (e) {
      print('[AuthProvider] FCM token registration failed: $e');
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      _token = response['token'];
      _user = User.fromJson(response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.signInWithGoogle();

      _token = response['token'];
      _user = User.fromJson(response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    // Unregister FCM token sebelum logout
    if (_token != null) {
      try {
        await FCMService().unregisterTokenFromBackend(_token!);
      } catch (_) {}
    }
    await _authService.logout();
    _user = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  // Update KYC Status
  Future<void> updateKycStatus(String kycStatus) async {
    if (_user == null) return;

    // Create updated user with new kycStatus
    _user = User(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      image: _user!.image,
      phone: _user!.phone,
      role: _user!.role,
      kycStatus: kycStatus,
      orderCount: _user!.orderCount,
      reviewCount: _user!.reviewCount,
      wishlistCount: _user!.wishlistCount,
    );

    // Save to storage
    await _authService.saveUser(_user!);

    print('[AuthProvider] KYC status updated to: $kycStatus');
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
