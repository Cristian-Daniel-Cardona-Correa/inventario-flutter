import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  // Notificador global para eventos de sesión expirada (401)
  static final ValueNotifier<bool> sessionExpiredNotifier = ValueNotifier<bool>(false);

  ApiClient._internal() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para inyectar token JWT y manejar errores 401
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Si la petición no es pública de autenticación, adjuntar token JWT
          final path = options.path;
          if (!path.contains('/auth/login') && !path.contains('/auth/registro')) {
            final token = await StorageService.instance.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Si el servidor responde 401 Unauthorized en una ruta protegida
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            if (!path.contains('/auth/login')) {
              // Token vencido o inválido: limpiar almacenamiento y notificar
              await StorageService.instance.clearSession();
              sessionExpiredNotifier.value = true;
            }
          }
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Dio get client => dio;
}
