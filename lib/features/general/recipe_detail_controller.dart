import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

/// Provider für die Details eines Rezepts
final recipeDetailProvider = FutureProvider.family<Recipe?, String>((
  ref,
  id,
) async {
  final repo = ref.read(backendRepoProvider);
  try {
    return await repo.getRecipeById(id);
  } catch (e) {
    print('Error while loading recipe: $e');
    return null;
  }
});
