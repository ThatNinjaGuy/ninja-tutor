import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like auth tokens
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  
  SecureStorageService._internal();
  
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  /// Save Firebase ID token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'firebase_token', value: token);
  }
  
  /// Get Firebase ID token
  Future<String?> getToken() async {
    return await _storage.read(key: 'firebase_token');
  }
  
  /// Delete Firebase ID token
  Future<void> deleteToken() async {
    await _storage.delete(key: 'firebase_token');
  }
  
  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
  
  /// Delete all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

