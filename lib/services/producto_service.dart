import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/producto.dart';
import 'api_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class ProductoService {
  final Dio _dio = ApiClient.instance.client;

  String get baseUrl => _dio.options.baseUrl;

  Future<List<Producto>> listarTodos() async {
    try {
      final response = await _dio.get('/productos');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => Producto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado al listar productos: $e');
    }
  }

  Future<Producto> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('/productos/$id');
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado al obtener producto: $e');
    }
  }

  Future<Producto> crear(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/productos', data: data);
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado al crear producto: $e');
    }
  }

  Future<Producto> actualizar(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/productos/$id', data: data);
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado al actualizar producto: $e');
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _dio.delete('/productos/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado al eliminar producto: $e');
    }
  }

  Future<String> subirImagen(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'upload.jpg',
        ),
      });

      final response =
          await _dio.post('/productos/upload-imagen', data: formData);

      if (response.data is Map && response.data['url'] != null) {
        final String relativeUrl = response.data['url'] as String;
        // Si el baseUrl es http://10.0.2.2:8080/api, el host es http://10.0.2.2:8080
        final uri = Uri.tryParse(baseUrl);
        if (uri != null) {
          final hostPart = '${uri.scheme}://${uri.host}:${uri.port}';
          return '$hostPart$relativeUrl';
        }
        return relativeUrl;
      }
      throw ApiException(
          message: 'El servidor no retornó la URL de la imagen');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error al subir imagen al servidor: $e');
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response != null) {
      final status = e.response?.statusCode;
      final dynamic body = e.response?.data;

      String message = 'Error en el servidor ($status)';
      Map<String, dynamic>? fieldErrors;

      if (body is Map<String, dynamic>) {
        if (body.containsKey('errores') && body['errores'] is Map) {
          fieldErrors = Map<String, dynamic>.from(body['errores'] as Map);
          final buffer = StringBuffer();
          fieldErrors.forEach((field, msg) {
            buffer.writeln('• $field: $msg');
          });
          message = 'Errores de validación:\n$buffer'.trim();
        } else if (body.containsKey('message') && body['message'] != null) {
          message = body['message'].toString();
        } else if (body.containsKey('error') && body['error'] != null) {
          message = body['error'].toString();
        }
      }

      if (status == 404) {
        return ApiException(
          message: message.isNotEmpty && message != 'Error en el servidor (404)'
              ? message
              : 'El producto solicitado no fue encontrado (404)',
          statusCode: 404,
        );
      }

      return ApiException(
        message: message,
        statusCode: status,
        errors: fieldErrors,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Tiempo de espera agotado al conectar con el servidor. Verifica que el backend esté ejecutándose.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'No se pudo conectar al servidor. Revisa tu archivo .env y asegúrate de que el backend esté activo en la URL configurada.',
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'La petición fue cancelada');
      default:
        return ApiException(
          message: 'Error de red o comunicación: ${e.message ?? 'Desconocido'}',
        );
    }
  }
}
