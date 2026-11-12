import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/perfil_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/productos/productos_list_screen.dart';
import '../screens/productos/producto_detail_screen.dart';
import '../screens/productos/producto_form_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: AuthService.authStateNotifier,
    redirect: (context, state) {
      final bool loggedIn = AuthService.authStateNotifier.value;
      final bool isLoggingIn = state.matchedLocation == '/login';

      // Si no ha iniciado sesión y no está en la pantalla de login, redirigir a /login
      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }

      // Si ya está autenticado e intenta ir a /login, redirigir al Dashboard principal
      if (loggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      // Ruta pública de inicio de sesión
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Rutas protegidas dentro del contenedor con barra de navegación inferior
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/productos',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductosListScreen(),
            ),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PerfilScreen(),
            ),
          ),
        ],
      ),

      // Rutas protegidas de gestión individual de productos
      GoRoute(
        path: '/productos/nuevo',
        builder: (context, state) => const ProductoFormScreen(),
      ),
      GoRoute(
        path: '/productos/:id/editar',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductoFormScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/productos/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductoDetailScreen(id: id);
        },
      ),
    ],
  );
}

class _ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithBottomNav({required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/productos')) {
      currentIndex = 1;
    } else if (location.startsWith('/perfil')) {
      currentIndex = 2;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/productos');
            case 2:
              context.go('/perfil');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Mi Sesión',
          ),
        ],
      ),
    );
  }
}
