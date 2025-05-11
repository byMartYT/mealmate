import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/models/recipe_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mealmate_new/theme/theme_controller.dart';

// SharedPreferences Key für Favoriten
const String kFavoritesKey = 'favorites';

// Provider für die aktuellen Favoriten (nur IDs)
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
      final prefs = ref.watch(prefsProvider);
      return FavoritesNotifier(prefs);
    });

// Provider für vollständige Favoriten-Rezepte
final favoritesRecipesProvider = FutureProvider<List<RecipeSummary>>((
  ref,
) async {
  final favoriteIds = ref.watch(favoritesProvider);
  if (favoriteIds.isEmpty) return [];

  final repo = ref.watch(backendRepoProvider);
  final recipes = <RecipeSummary>[];

  for (final id in favoriteIds) {
    final recipe = await repo.getRecipeById(id);
    if (recipe != null) {
      recipes.add(recipe);
    }
  }

  return recipes;
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  FavoritesNotifier(this._prefs) : super([]) {
    _loadFavorites();
  }

  // Favoriten aus SharedPreferences laden
  void _loadFavorites() {
    final favoritesJson = _prefs.getStringList(kFavoritesKey);
    if (favoritesJson != null) {
      state = favoritesJson;
    }
  }

  // Favoriten in SharedPreferences speichern
  Future<void> _saveFavorites() async {
    await _prefs.setStringList(kFavoritesKey, state);
  }

  // Prüft, ob ein Rezept favorisiert ist
  bool isFavorite(String recipeId) {
    return state.contains(recipeId);
  }

  // Fügt ein Rezept zu den Favoriten hinzu oder entfernt es
  Future<void> toggleFavorite(String recipeId) async {
    if (isFavorite(recipeId)) {
      state = state.where((id) => id != recipeId).toList();
    } else {
      state = [...state, recipeId];
    }
    await _saveFavorites();
  }
}
