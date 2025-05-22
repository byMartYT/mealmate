import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/favorites/favorites_provider.dart';
import 'package:mealmate_new/features/search/search_item.dart';
import 'package:mealmate_new/features/widgets/error_screen.dart';
import 'package:mealmate_new/features/widgets/loading_screen.dart';
import 'package:mealmate_new/main.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesRecipesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some to your favorites',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: kPadding,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) => SearchItem(recipes[index]),
          );
        },
        loading: () => const LoadingScreen(message: 'Loading favorites...'),
        error:
            (error, stack) =>
                ErrorScreen.general(message: 'Fehler beim Laden: $error'),
      ),
    );
  }
}
