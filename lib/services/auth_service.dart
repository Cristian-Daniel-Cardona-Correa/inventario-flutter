import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'producto_service.dart';
import 'storage_service.dart';

class AuthService {
  static AuthService? _instance;
  final Dio _dio = ApiClient.instance.client;
  final StorageService _storage = StorageService.instance;

  // Notificador reactivo del estado de autenticación para go_router
  static final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  AuthService._internal();

  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  /// Inicializa y verifica el estado de la sesión almacenada
  Future<bool> initAuth() async {
    final loggedIn = await _storage.isLoggedIn();
    authStateNotifier.value = loggedIn;
    return loggedIn;
  }

  /// Inicia sesión consumiendo POST /auth/login con Dio
  Future<Usuario> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final String token = data['token'] as String;

      final usuario = Usuario(
        username: data['username'] as String? ?? username.trim(),
        email: data['email'] as String? ?? '',
        nombre: data['nombre'] as String? ?? username.trim(),
        rol: data['rol'] as String? ?? 'ROLE_USER',
        token: token,
      );

      // Almacenamiento seguro del token y persistencia de sesión
      await _storage.saveToken(token);
      await _storage.saveUser(usuario);

      // Notificar cambio de estado para navegación
      authStateNotifier.value = true;
      ApiClient.sessionExpiredNotifier.value = false;

      return usuario;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException(
          message: 'Credenciales incorrectas: Usuario o contraseña inválidos.',
          statusCode: 401,
        );
      }
      throw _handleError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error inesperado durante el inicio de sesión: $e');
    }
  }

  /// Registra una nueva cuenta de usuario
  Future<Usuario> registro({
    required String username,
    required String password,
    required String nombre,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/registro',
        data: {
          'username': username.trim(),
          'password': password,
          'nombre': nombre.trim(),
          'email': email.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return Usuario.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al registrar usuario: $e');
    }
  }

  /// Cierra la sesión activa, borra credenciales seguras y actualiza el router
  Future<void> logout() async {
    await _storage.clearSession();
    authStateNotifier.value = false;
  }

  /// Retorna el usuario guardado localmente
  Future<Usuario?> getUsuarioActual() async {
    return await _storage.getUser();
  }

  /// Obtiene el token seguro actual
  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  /// Verifica si hay una sesión activa válida
  Future<bool> isAuthenticated() async {
    return await _storage.isLoggedIn();
  }

  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final status = e.response?.statusCode;
      final dynamic body = e.response?.data;

      String message = 'Error en el servidor ($status)';
      if (body is Map<String, dynamic>) {
        if (body.containsKey('message') && body['message'] != null) {
          message = body['message'].toString();
        } else if (body.containsKey('error') && body['error'] != null) {
          message = body['error'].toString();
        }
      }

      return ApiException(message: message, statusCode: status);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'No se pudo conectar al backend. Verifique que esté activo.',
      );
    }

    return ApiException(message: 'Error de comunicación: ${e.message ?? 'Desconocido'}');
  }
}
