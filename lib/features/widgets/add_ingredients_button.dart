import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/shopping_list/shopping_list_provider.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class AddIngredientsButton extends ConsumerWidget {
  final Recipe recipe;

  const AddIngredientsButton({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF93D385), // Obere Farbe
            Color(0xFF177B00), // Untere Farbe
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          // Füge alle Zutaten des Rezepts zur Einkaufsliste hinzu
          await ref
              .read(shoppingListProvider.notifier)
              .addRecipeIngredients(recipe);

          // Zeige Feedback
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${recipe.ingredients.length} ingredients added to shopping list',
              ),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Anzeigen',
                onPressed: () {
                  // Navigiere zur Einkaufsliste mit GoRouter
                  GoRouter.of(context).go('/list');
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Add to shopping list',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
