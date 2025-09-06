import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../services/api/api_service.dart';

/// Simple user data class for basic auth info
class SimpleUser {
  final String id;
  final String name;
  final String email;
  final String? token;

  const SimpleUser({
    required this.id,
    required this.name,
    required this.email,
    this.token,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'token': token,
      };

  factory SimpleUser.fromJson(Map<String, dynamic> json) => SimpleUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        token: json['token'] as String?,
      );
}

/// Simple authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, SimpleUser?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<SimpleUser?> {
  AuthNotifier() : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('simple_user');
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
          Uri.splitQueryString(userJson),
        );
        state = SimpleUser.fromJson(userData);
      }
    } catch (e) {
      // Ignore loading errors
    }
  }

  Future<void> login(String email, String password) async {
    final apiService = ApiService();
    
    // Login to backend
    final loginResponse = await apiService.login(email, password);
    
    // Set the auth token
    final token = loginResponse['access_token'] as String?;
    if (token != null) {
      apiService.setAuthToken(token);
      
      // Get user profile
      final profileResponse = await apiService.getUserProfile();
      
      // Create simple user
      final user = SimpleUser(
        id: profileResponse['id'] as String,
        name: profileResponse['name'] as String,
        email: profileResponse['email'] as String,
        token: token,
      );
      
      // Save to SharedPreferences
      await _saveUser(user);
      
      state = user;
    }
  }

  Future<void> register(String name, String email, String password) async {
    final apiService = ApiService();
    
    // Register to backend
    await apiService.register(
      name: name,
      email: email,
      password: password,
    );
    
    // Don't auto-login after registration
    // User should login manually
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('simple_user');
    await prefs.remove(AppConstants.authTokenKey);
    
    // Clear API token
    final apiService = ApiService();
    apiService.clearAuthToken();
    
    state = null;
  }

  Future<void> _saveUser(SimpleUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = user.toJson();
    final userString = userData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    await prefs.setString('simple_user', userString);
    await prefs.setString(AppConstants.authTokenKey, user.token ?? '');
  }
}
