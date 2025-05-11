import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/general/recipe_detail_controller.dart';

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
                    appBar: AppBar(title: Text(recipe.title)),
                    body: Center(),
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
