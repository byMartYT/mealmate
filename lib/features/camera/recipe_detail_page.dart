import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/features/camera/ingredients_detection_provider.dart';
import 'package:mealmate_new/features/general/ingredients_list.dart';
import 'package:mealmate_new/features/widgets/add_ingredients_button.dart';
import 'package:mealmate_new/features/widgets/error_screen.dart';
import 'package:mealmate_new/features/widgets/instructions_list.dart';
import 'package:mealmate_new/features/widgets/loading_screen.dart';
import 'package:mealmate_new/features/widgets/meta_list.dart';
import 'package:mealmate_new/models/ingredient.dart';
import 'package:mealmate_new/models/recipe_summary.dart';
import 'package:uuid/v4.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  final String recipeTitle;

  const RecipeDetailPage({super.key, required this.recipeTitle});

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  bool _isLoading = true;
  Recipe? _recipe;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Zutaten aus dem Provider holen
      final ingredients = ref.read(ingredientsDetectionProvider).ingredients;
      final ingredientData = ingredients.map((ing) => ing.toJson()).toList();

      // Backend-Service aufrufen
      final backendRepo = ref.read(backendRepoProvider);
      final details = await backendRepo.getRecipeDetails(
        widget.recipeTitle,
        ingredientData,
      );

      // Auf Fehler prüfen
      if (details.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = details['error'];
        });
        return;
      }

      // Konvertiere Details in Recipe
      final recipe = Recipe(
        id: UuidV4().toString(),
        title: details['title'] ?? widget.recipeTitle,
        cookingTime: details['cookTime']?.toString() ?? 'N/A',
        servings: details['servings']?.toString() ?? 'N/A',
        category: details['category'] ?? '_',
        image: details['image'] ?? '_',
        instructions:
            (details['instructions'] as List? ?? [])
                .map((item) => item.toString())
                .toList(),
        ingredients:
            (details['ingredients'] as List? ?? [])
                .map((item) => Ingredient.fromJson(item))
                .toList(),
        cuisine: details['cuisine'],
        tags:
            details['tags'] != null ? List<String>.from(details['tags']) : null,
      );

      // Erfolgreich geladen
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading recipe details: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading Recipe...' : widget.recipeTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingScreen.recipeGeneration();
    }

    if (_errorMessage != null) {
      return ErrorScreen.retry(
        message: _errorMessage!,
        onRetry: _loadRecipeDetails,
      );
    }

    // Rezeptdetails anzeigen
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel und Beschreibung
            Text(
              _recipe?.title ?? widget.recipeTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MetaList([
              Meta(
                text: "${_recipe?.servings ?? 'N/A'} servings",
                icon: Icons.room_service_outlined,
              ),
              Meta(
                text: "${_recipe?.cookingTime ?? 'N/A'} min",
                icon: Icons.timer_outlined,
              ),
            ]),
            // Informationen zu Zeiten und Portionen
            const SizedBox(height: 24),
            if (_recipe != null) AddIngredientsButton(recipe: _recipe!),
            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 24),
            if (_recipe != null) IngredientsList(_recipe!.ingredients),
            const SizedBox(height: 24),
            if (_recipe != null) InstructionsList(_recipe!.instructions),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Diese Methode wird nicht mehr benötigt, da wir jetzt InstructionsList verwenden
}
