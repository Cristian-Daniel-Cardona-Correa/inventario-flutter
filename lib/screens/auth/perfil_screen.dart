import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService.instance;

  Usuario? _usuario;
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosSesion();
  }

  Future<void> _cargarDatosSesion() async {
    setState(() {
      _isLoading = true;
    });

    final user = await _authService.getUsuarioActual();
    final token = await _authService.getToken();

    if (mounted) {
      setState(() {
        _usuario = user;
        _token = token;
        _isLoading = false;
      });
    }
  }

  String _ofuscarToken(String? token) {
    if (token == null || token.isEmpty) return 'No existe token almacenado';
    if (token.length <= 25) return '${token.substring(0, 8)}... (Almacenado de forma segura)';
    return '${token.substring(0, 16)}...${token.substring(token.length - 8)} (Almacenado en Secure Storage)';
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión actual? '
          'Se eliminará el token de autenticación del dispositivo y se restringirá el acceso a los servicios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _authService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión finalizada correctamente'),
            backgroundColor: Color(0xFF1565C0),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Sesión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarDatosSesion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta Principal del Usuario
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                            child: Text(
                              _usuario?.nombre.isNotEmpty == true
                                  ? _usuario!.nombre[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _usuario?.nombre ?? 'Usuario Autenticado',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${_usuario?.username ?? 'sin_usuario'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Badge de Rol
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _usuario?.rol ?? 'ROLE_USER',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta de Estado y Seguridad
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles de Seguridad de la Sesión',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Divider(height: 24),

                          // Estado de la Sesión
                          _buildInfoTile(
                            icon: Icons.verified_user_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            title: 'Estado de Autenticación',
                            subtitle: _token != null ? 'Sesión Activa' : 'Sin Sesión',
                            isHighlighted: true,
                          ),
                          const SizedBox(height: 12),

                          // Correo Electrónico
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            iconColor: Colors.blue.shade700,
                            title: 'Correo Electrónico',
                            subtitle: _usuario?.email.isNotEmpty == true
                                ? _usuario!.email
                                : 'No especificado',
                          ),
                          const SizedBox(height: 12),

                          // Tipo de Autenticación
                          _buildInfoTile(
                            icon: Icons.security_rounded,
                            iconColor: Colors.indigo,
                            title: 'Esquema de Autorización',
                            subtitle: 'JSON Web Token (Bearer)',
                          ),
                          const SizedBox(height: 12),

                          // Indicador de Token Seguro
                          _buildInfoTile(
                            icon: Icons.key_rounded,
                            iconColor: Colors.deepPurple,
                            title: 'Token JWT Almacenado',
                            subtitle: _ofuscarToken(_token),
                            note: 'El token completo se guarda encriptado mediante hardware seguro (flutter_secure_storage).',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de Cerrar Sesión
                  ElevatedButton.icon(
                    onPressed: _confirmarCerrarSesion,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? note,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted ? iconColor : const Color(0xFF1E293B),
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 4),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
