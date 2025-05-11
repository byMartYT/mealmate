import 'package:mealmate_new/models/ingredient.dart';

/// Ein Element in der Einkaufsliste
class ShoppingListItem {
  final String id; // Eindeutige ID für das Item
  final String recipeId; // ID des Rezepts, aus dem das Item stammt
  final String recipeName; // Name des Rezepts für die Anzeige
  final String recipeImage; // Bild-URL des Rezepts
  final Ingredient ingredient; // Die eigentliche Zutat
  bool isChecked; // Status (gekauft/nicht gekauft)

  ShoppingListItem({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.recipeImage,
    required this.ingredient,
    this.isChecked = false,
  });

  // Kopiere mit Änderungen
  ShoppingListItem copyWith({
    String? id,
    String? recipeId,
    String? recipeName,
    String? recipeImage,
    Ingredient? ingredient,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      recipeImage: recipeImage ?? this.recipeImage,
      ingredient: ingredient ?? this.ingredient,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  // Konvertierung zu Map für JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeImage': recipeImage,
      'ingredient': ingredient.toJson(),
      'isChecked': isChecked,
    };
  }

  // Erstellen aus Map (JSON)
  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'],
      recipeId: json['recipeId'],
      recipeName: json['recipeName'],
      recipeImage: json['recipeImage'] ?? '',
      ingredient: Ingredient.fromJson(json['ingredient']),
      isChecked: json['isChecked'] ?? false,
    );
  }
}
