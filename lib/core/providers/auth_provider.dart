import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
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

/// Auth state for managing login dialog visibility
class AuthState {
  const AuthState({
    this.showLoginDialog = false,
    this.authErrorMessage,
    this.returnRoute,
  });

  final bool showLoginDialog;
  final String? authErrorMessage;
  final String? returnRoute;

  AuthState copyWith({
    bool? showLoginDialog,
    String? authErrorMessage,
    String? returnRoute,
  }) {
    return AuthState(
      showLoginDialog: showLoginDialog ?? this.showLoginDialog,
      authErrorMessage: authErrorMessage ?? this.authErrorMessage,
      returnRoute: returnRoute ?? this.returnRoute,
    );
  }
}

/// Auth state provider for managing authentication UI state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  void showLoginDialog({String? message, String? returnRoute}) {
    state = state.copyWith(
      showLoginDialog: true,
      authErrorMessage: message ?? AppStrings.sessionExpired,
      returnRoute: returnRoute,
    );
  }

  void hideLoginDialog() {
    state = state.copyWith(
      showLoginDialog: false,
      authErrorMessage: null,
      returnRoute: null,
    );
  }

  void setReturnRoute(String route) {
    state = state.copyWith(returnRoute: route);
  }
}

/// Simple authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, SimpleUser?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<SimpleUser?> {
  AuthNotifier(this._ref) : super(null) {
    _loadUser();
    _setupAuthErrorCallback();
  }

  final Ref _ref;

  void _setupAuthErrorCallback() {
    ApiService().onAuthError = _handleAuthError;
  }

  void _handleAuthError(ApiException error, {String? currentRoute}) {
    debugPrint('Auth error detected: ${error.message}');
    
    // Auto-logout
    logout();
    
    // Show login dialog with return route preserved
    _ref.read(authStateProvider.notifier).showLoginDialog(
      message: error.message,
      returnRoute: currentRoute,
    );
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('simple_user');
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
          Uri.splitQueryString(userJson),
        );
        final user = SimpleUser.fromJson(userData);
        
        // Set token in API service
        if (user.token != null) {
          ApiService().setAuthToken(user.token!);
          
          // Validate token with backend
          final isValid = await validateToken();
          if (isValid) {
            state = user;
          } else {
            // Token is invalid, clear it
            await logout();
          }
        } else {
          state = user;
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      // If there's an error loading, clear the state
      state = null;
    }
  }

  /// Validate the current auth token with backend
  Future<bool> validateToken() async {
    if (state?.token == null) return false;
    
    try {
      final apiService = ApiService();
      await apiService.getUserProfile();
      return true;
    } catch (e) {
      if (e is ApiException && e.isAuthError) {
        return false;
      }
      // For other errors (network, etc.), assume token is still valid
      return true;
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
      
      // Hide login dialog and clear return route
      _ref.read(authStateProvider.notifier).hideLoginDialog();
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
    
    // Hide login dialog if showing
    _ref.read(authStateProvider.notifier).hideLoginDialog();
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
