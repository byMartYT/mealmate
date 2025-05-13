import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/favorites/favorites_provider.dart';
import 'package:mealmate_new/features/general/ingredients_list.dart';
import 'package:mealmate_new/features/general/recipe_detail_controller.dart';
import 'package:mealmate_new/features/widgets/add_ingredients_button.dart';
import 'package:mealmate_new/features/widgets/error_screen.dart';
import 'package:mealmate_new/features/widgets/instructions_list.dart';
import 'package:mealmate_new/features/widgets/loading_screen.dart';
import 'package:mealmate_new/features/widgets/meta_list.dart';
import 'package:mealmate_new/features/widgets/tag_list.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class RecipeDetailPage extends ConsumerWidget {
  final String id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(recipeDetailProvider(id));

    return detailAsync.when(
      data:
          (recipe) =>
              recipe != null
                  ? Scaffold(
                    appBar: AppBar(
                      title: Text(recipe.title),
                      actions: [
                        Consumer(
                          builder: (context, ref, _) {
                            final isFavorite = ref
                                .watch(favoritesProvider)
                                .contains(recipe.id);
                            return IconButton(
                              onPressed: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(recipe.id);
                              },
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    body: RecipeDetail(recipe),
                  )
                  : const Scaffold(
                    body: Center(child: Text('Recipe not found')),
                  ),
      loading:
          () =>
              const Scaffold(body: LoadingScreen(message: 'Loading recipe...')),
      error:
          (e, _) => Scaffold(
            body: ErrorScreen.general(
              message: 'Error: $e',
              withScaffold: false,
            ),
          ),
    );
  }
}

class RecipeDetail extends StatelessWidget {
  const RecipeDetail(this.recipe, {super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Image.network(recipe.image),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.tags?.isNotEmpty == true) ...[
                TagList(recipe.tags!),
                const SizedBox(height: 12),
              ],
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              MetaList([
                Meta(text: recipe.cookingTime, icon: Icons.timer_outlined),
                Meta(text: recipe.servings, icon: Icons.room_service_outlined),
              ]),
              const SizedBox(height: 16),
              AddIngredientsButton(recipe: recipe),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 16),
              IngredientsList(recipe.ingredients),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 16),
              InstructionsList(recipe.instructions),
            ],
          ),
        ),
      ],
    );
  }
}
