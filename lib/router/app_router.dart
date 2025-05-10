import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/favorites/favorites_page.dart';
import 'package:mealmate_new/features/shopping_list/shopping_page.dart';
import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/camera/camera_page.dart';

final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => TabScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (_, __) => const SearchPage(),
          ),
          GoRoute(
            path: '/camera',
            name: 'camera',
            pageBuilder: (_, __) => const NoTransitionPage(child: CameraPage()),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (_, __) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/shopping',
            name: 'shopping',
            builder: (_, __) => const ShoppingPage(),
          ),
        ],
      ),
    ],
  );
});

/// BottomNavigation wrapper
class TabScaffold extends ConsumerWidget {
  const TabScaffold({required this.child, super.key});
  final Widget child;

  static const _tabs = [
    ('/', Icons.home, 'Home'),
    ('/search', Icons.search, 'Search'),
    ('/camera', Icons.camera, 'Scan'),
    ('/favorites', Icons.star, 'Favs'),
    ('/shopping', Icons.shopping_cart, 'List'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = GoRouter.of(context);
    final location =
        goRouter.routerDelegate.currentConfiguration.uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabs.indexWhere((t) => location.startsWith(t.$1)),
        onDestinationSelected: (i) => goRouter.go(_tabs[i].$1),
        destinations:
            _tabs
                .map(
                  (t) => NavigationDestination(icon: Icon(t.$2), label: t.$3),
                )
                .toList(),
      ),
    );
  }
}
