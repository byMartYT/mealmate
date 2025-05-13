import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mealmate_new/models/recipe_summary.dart';
import 'package:mealmate_new/models/shopping_list_item.dart';
import 'package:mealmate_new/theme/theme_controller.dart';
import 'package:uuid/uuid.dart';

const String kShoppingListKey = 'shopping_list';

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>((ref) {
      final prefs = ref.watch(prefsProvider);
      return ShoppingListNotifier(prefs);
    });

class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  ShoppingListNotifier(this._prefs) : super([]) {
    _loadShoppingList();
  }

  // Einkaufsliste aus SharedPreferences laden
  void _loadShoppingList() {
    try {
      final jsonList = _prefs.getStringList(kShoppingListKey);
      if (jsonList != null) {
        state =
            jsonList
                .map((item) => ShoppingListItem.fromJson(json.decode(item)))
                .toList();
      }
    } catch (e) {
      print('Fehler beim Laden der Einkaufsliste: $e');
      // Bei fehlerhaften Daten mit leerer Liste starten
      state = [];
    }
  }

  // Einkaufsliste in SharedPreferences speichern
  Future<void> _saveShoppingList() async {
    try {
      final jsonList = state.map((item) => json.encode(item.toJson())).toList();
      await _prefs.setStringList(kShoppingListKey, jsonList);
    } catch (e) {
      print('Fehler beim Speichern der Einkaufsliste: $e');
    }
  }

  // Füge alle Zutaten eines Rezepts zur Einkaufsliste hinzu
  Future<void> addRecipeIngredients(Recipe recipe) async {
    final newItems =
        recipe.ingredients
            .map(
              (ingredient) => ShoppingListItem(
                id: _uuid.v4(),
                recipeId: recipe.id,
                recipeName: recipe.title,
                recipeImage: recipe.image,
                ingredient: ingredient,
                isChecked: false,
              ),
            )
            .toList();

    state = [...state, ...newItems];
    await _saveShoppingList();
  }

  // Eine Zutat vom Einkaufszettel entfernen
  Future<void> removeItem(String itemId) async {
    state = state.where((item) => item.id != itemId).toList();
    await _saveShoppingList();
  }

  // Markiere eine Zutat als gekauft/nicht gekauft
  Future<void> toggleItemCheck(String itemId) async {
    state =
        state.map((item) {
          if (item.id == itemId) {
            return item.copyWith(isChecked: !item.isChecked);
          }
          return item;
        }).toList();
    await _saveShoppingList();
  }

  // Alle Zutaten eines bestimmten Rezepts entfernen
  Future<void> removeRecipeItems(String recipeId) async {
    state = state.where((item) => item.recipeId != recipeId).toList();
    await _saveShoppingList();
  }

  // Alle erledigten Zutaten entfernen
  Future<void> removeCheckedItems() async {
    state = state.where((item) => !item.isChecked).toList();
    await _saveShoppingList();
  }

  // Gesamte Einkaufsliste leeren
  Future<void> clearShoppingList() async {
    state = [];
    await _saveShoppingList();
  }
}
