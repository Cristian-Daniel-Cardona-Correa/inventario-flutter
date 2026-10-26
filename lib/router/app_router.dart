import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/dashboard_screen.dart';
import '../screens/productos/productos_list_screen.dart';
import '../screens/productos/producto_detail_screen.dart';
import '../screens/productos/producto_form_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
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
        ],
      ),
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
    final int currentIndex = location.startsWith('/productos') ? 1 : 0;

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
        ],
      ),
    );
  }
}
