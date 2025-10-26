import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../../services/api/api_service.dart';
import '../../services/storage/secure_storage_service.dart';

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
    _setupAuthStateListener();
    _setupAuthErrorCallback();
  }

  final Ref _ref;
  final _firebaseAuth = FirebaseAuth.instance;
  final _secureStorage = SecureStorageService();

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

  void _setupAuthStateListener() {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          // User is signed in, get ID token
          final token = await firebaseUser.getIdToken();
          if (token != null) {
            // Set token in API service
            ApiService().setAuthToken(token);
            
            // Sync user with backend (creates Firestore document if doesn't exist)
            try {
              final apiService = ApiService();
              final userProfile = await apiService.syncUser();
              
              // Update state with backend user data
              state = SimpleUser(
                id: userProfile['id'] as String,
                name: userProfile['name'] as String,
                email: userProfile['email'] as String,
                token: token,
              );
              
              debugPrint('User synced with backend: ${userProfile['email']}');
            } catch (e) {
              debugPrint('Error syncing user with backend: $e');
              // Fall back to Firebase user data
              state = SimpleUser(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'User',
                email: firebaseUser.email ?? '',
                token: token,
              );
            }
            
            // Save to secure storage
            await _secureStorage.saveToken(token);
            await _secureStorage.saveUserId(firebaseUser.uid);
            
            debugPrint('User authenticated: ${firebaseUser.email}');
          }
        } catch (e) {
          debugPrint('Error in auth state listener: $e');
        }
      } else {
        // User is signed out
        state = null;
        ApiService().clearAuthToken();
        await _secureStorage.clearAll();
        debugPrint('User signed out');
      }
    });
  }

  Future<void> login(String email, String password) async {
    try {
      // Sign in with Firebase Authentication
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Token will be automatically handled by authStateChanges listener
      // Hide login dialog
      _ref.read(authStateProvider.notifier).hideLoginDialog();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      
      throw ApiException(
        statusCode: 401,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      throw ApiException(
        statusCode: 500,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      // Create user with Firebase Authentication
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name - ensure it's saved properly
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
        
        // Wait a bit to ensure display name is saved
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Re-fetch user to get the updated display name
        await user.reload();
        
        debugPrint('User registered successfully: $email with name: ${user.displayName}');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase registration error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. Please use a stronger password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      
      throw ApiException(
        statusCode: 400,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      throw ApiException(
        statusCode: 500,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Clear secure storage
      await _secureStorage.clearAll();
      
      // Clear API token
      ApiService().clearAuthToken();
      
      // Update state
      state = null;
      
      // Hide login dialog if showing
      _ref.read(authStateProvider.notifier).hideLoginDialog();
      
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}
