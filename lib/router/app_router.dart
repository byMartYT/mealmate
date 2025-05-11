import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/favorites/favorites_page.dart';
import 'package:mealmate_new/features/general/recipe_detail_page.dart';
import 'package:mealmate_new/features/shopping_list/shopping_page.dart';
import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/camera/camera_page.dart';

final _shellKey = GlobalKey<NavigatorState>();

class Routes {
  static const String home = '/home';
  static const String searchPath = '/search';
  static const String cameraPath = '/camera';
  static const String favoritesPath = '/favorites';
  static const String listPath = '/list';
}

final router = GoRouter(
  navigatorKey: _shellKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder:
          (context, state, navigationShell) =>
              TabScaffold(child: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => HomePage(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder:
                      (context, state) =>
                          RecipeDetailPage(id: state.extra as String),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.searchPath,
              builder: (context, state) => SearchPage(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder:
                      (context, state) =>
                          RecipeDetailPage(id: state.extra as String),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.cameraPath,
              builder: (context, state) => CameraPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.favoritesPath,
              builder: (context, state) => FavoritesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.listPath,
              builder: (context, state) => ShoppingPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// BottomNavigation wrapper
class TabScaffold extends StatelessWidget {
  const TabScaffold({required this.child, super.key});

  final StatefulNavigationShell child;

  static const _tabs = [
    (Routes.home, Icons.home_outlined, 'Home', Icons.home),
    (Routes.searchPath, Icons.search, 'Search', Icons.search),
    (Routes.cameraPath, Icons.camera_alt_outlined, 'Scan', Icons.camera_alt),
    (Routes.favoritesPath, Icons.favorite_border, 'Favs', Icons.favorite),
    (
      Routes.listPath,
      Icons.shopping_cart_outlined,
      'List',
      Icons.shopping_cart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // final idx = _tabs.indexWhere((t) => .startsWith(t.$1));
    // final selectedIndex = idx < 0 ? 0 : idx;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: child.currentIndex,
        onDestinationSelected: (i) {
          // Double-tap on the same tab resets to branch root
          if (i == child.currentIndex) {
            child.goBranch(i, initialLocation: true);
          } else {
            child.goBranch(i);
          }
        },
        destinations:
            _tabs
                .map(
                  (tab) => NavigationDestination(
                    icon: Icon(tab.$2),
                    label: tab.$3,
                    selectedIcon: Icon(tab.$4),
                  ),
                )
                .toList(),
      ),
    );
  }
}
