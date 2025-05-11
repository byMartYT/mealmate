import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/general/ingredients_list.dart';
import 'package:mealmate_new/features/general/recipe_detail_controller.dart';
import 'package:mealmate_new/features/widgets/instructions_list.dart';
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
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border),
                        ),
                      ],
                    ),
                    body: RecipeDetail(recipe),
                  )
                  : const Scaffold(
                    body: Center(child: Text('Rezept nicht gefunden')),
                  ),
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class RecipeDetail extends StatelessWidget {
  const RecipeDetail(this.recipe, {super.key});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Image.network(recipe.image),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.tags?.isNotEmpty == true) TagList(recipe.tags!),
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              MetaList([
                Meta(
                  text: recipe.cookingTime,
                  icon: Icons.room_service_outlined,
                ),
                Meta(text: recipe.servings, icon: Icons.timer_outlined),
              ]),
              Divider(height: 1, color: Colors.grey[300], thickness: 1),
              IngredientsList(recipe.ingredients),
              const SizedBox(height: 2),
              Divider(height: 1, color: Colors.grey[300], thickness: 1),
              InstructionsList(recipe.instructions),
            ],
          ),
        ),
      ],
    );
  }
}
