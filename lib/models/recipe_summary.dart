import 'package:mealmate_new/models/ingredient.dart';

class Recipe {
  final String id;
  final String title;
  final String cookingTime;
  final String servings;
  final String? cuisine;
  final String category;
  final String image;
  final List<String>? tags;
  final List<String> instructions;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.cookingTime,
    required this.servings,
    this.cuisine,
    required this.category,
    required this.image,
    required this.instructions,
    this.tags,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Konvertiere MongoDB ObjectId zu String, falls notwendig
    final id = json['_id'] ?? json['id'];

    return Recipe(
      id: id.toString(),
      title: json['title'],
      ingredients:
          (json['ingredients'] as List<dynamic>)
              .map((ingredient) => Ingredient.fromJson(ingredient))
              .toList(),
      cookingTime: json['cookingTime'],
      servings: json['servings'],
      instructions:
          json['instructions'] != null
              ? List<String>.from(json['instructions'])
              : [],
      cuisine: json['cuisine'],
      category: json['category'],
      image: json['image'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  // Getter für die Bildgröße wird nicht mehr benötigt,
  // da wir die vollständige URL vom Backend erhalten

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cookingTime': cookingTime,
      'servings': servings,
      'cuisine': cuisine,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'category': category,
      'image': image,
      'tags': tags,
    };
  }
}
