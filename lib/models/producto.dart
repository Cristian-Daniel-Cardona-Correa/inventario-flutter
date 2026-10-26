class Producto {
  final int id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;
  final String? imagenUrl;

  const Producto({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      categoria: json['categoria'] as String,
      imagenUrl: json['imagenUrl'] as String? ?? json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
    };
  }

  Map<String, dynamic> toCreateUpdateJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    double? precio,
    int? cantidad,
    String? categoria,
    String? imagenUrl,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  double get valorTotal => precio * cantidad;

  /// Retorna la URL completa de la imagen, resolviendo rutas relativas (/uploads/...)
  String? resolvedImageUrl(String baseUrl) {
    if (imagenUrl == null || imagenUrl!.trim().isEmpty) return null;
    final trimmed = imagenUrl!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri != null) {
      final hostPart = '${uri.scheme}://${uri.host}:${uri.port}';
      return '$hostPart$trimmed';
    }
    return trimmed;
  }
}
