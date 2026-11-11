class Usuario {
  final String username;
  final String email;
  final String nombre;
  final String rol;
  final String? token;

  const Usuario({
    required this.username,
    required this.email,
    required this.nombre,
    required this.rol,
    this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      rol: json['rol'] as String? ?? 'ROLE_USER',
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'nombre': nombre,
      'rol': rol,
      if (token != null) 'token': token,
    };
  }

  Usuario copyWith({
    String? username,
    String? email,
    String? nombre,
    String? rol,
    String? token,
  }) {
    return Usuario(
      username: username ?? this.username,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      token: token ?? this.token,
    );
  }

  bool get isAdmin => rol.toUpperCase().contains('ADMIN');
}
