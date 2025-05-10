import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/spoonacular.dart';
import 'package:mealmate_new/models/recipe_detail.dart';

final recipeDetailProvider = FutureProvider.family<RecipeDetail, int>((
  ref,
  id,
) {
  final repo = ref.read(spoonRepoProvider);
  return repo.bulk([id]).then((list) => list.first);
});

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(recipeDetailProvider(id));

    return detailAsync.when(
      data:
          (recipe) => Scaffold(
            appBar: AppBar(title: Text(recipe.title)),
            body: Center(),
          ),
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
