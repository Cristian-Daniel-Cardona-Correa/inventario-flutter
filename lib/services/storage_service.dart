import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class StorageService {
  static StorageService? _instance;

  // Almacenamiento Seguro (Hardware KeyStore en Android / Keychain en iOS)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const String _tokenKey = 'jwt_access_token';
  static const String _userKey = 'usuario_info_publica';
  static const String _isLoggedKey = 'is_logged_in';

  StorageService._internal();

  static StorageService get instance {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  // =========================================================================
  // GESTIÓN DEL TOKEN JWT (Seguro: flutter_secure_storage)
  // =========================================================================

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // =========================================================================
  // GESTIÓN DE INFORMACIÓN NO SENSIBLE DEL USUARIO (shared_preferences)
  // =========================================================================

  Future<void> saveUser(Usuario user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    await prefs.setBool(_isLoggedKey, true);
  }

  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null || userString.isEmpty) return null;
    try {
      final Map<String, dynamic> userMap = jsonDecode(userString) as Map<String, dynamic>;
      return Usuario.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final tokenExists = await hasToken();
    if (!tokenExists) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedKey) ?? false;
  }

  // =========================================================================
  // LIMPIEZA DE SESIÓN (Cerrar Sesión)
  // =========================================================================

  Future<void> clearSession() async {
    await deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedKey, false);
  }
}
