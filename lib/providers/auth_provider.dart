import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _error;
  String? _accessToken;
  CustomerInfo? _customer;

  AuthProvider({AuthService? service})
      : _service = service ?? AuthService();

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get accessToken => _accessToken;
  CustomerInfo? get customer => _customer;

  /// Check for an existing session on app start.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.cachedAccessTokenKey);

      if (token != null && token.isNotEmpty) {
        final isValid = await _service.verifyToken(token);
        if (isValid) {
          _accessToken = token;
          _isLoggedIn = true;
          // Fetch customer profile
          _customer = await _service.fetchCustomer(token);
        } else {
          await prefs.remove(AppConstants.cachedAccessTokenKey);
        }
      }
    } catch (_) {
      // No saved session
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Register a new user.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      _accessToken = result.accessToken;
      _customer = result.customer;
      _isLoggedIn = true;
      _error = null;
      await _saveToken(result.accessToken!);
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Log in an existing user.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.login(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      _accessToken = result.accessToken;
      _customer = result.customer;
      _isLoggedIn = true;
      _error = null;
      await _saveToken(result.accessToken!);
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Update the customer's profile.
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    if (_accessToken == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.updateCustomer(
      accessToken: _accessToken!,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    if (result.isSuccess) {
      // Refresh customer info
      _customer = await _service.fetchCustomer(_accessToken!);
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Change the customer's password.
  Future<bool> changePassword({required String newPassword}) async {
    if (_accessToken == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.changePassword(
      accessToken: _accessToken!,
      newPassword: newPassword,
    );

    if (!result.isSuccess) {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Send a password reset email.
  Future<bool> recoverPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.recoverPassword(email: email);

    if (!result.isSuccess) {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Log out the current user.
  Future<void> logout() async {
    if (_accessToken != null) {
      await _service.logout(_accessToken!);
    }

    _accessToken = null;
    _customer = null;
    _isLoggedIn = false;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.cachedAccessTokenKey);

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cachedAccessTokenKey, token);
  }
}
