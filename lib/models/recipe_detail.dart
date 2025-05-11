import 'package:mealmate_new/models/ingredient.dart';

class RecipeDetail {
  final String id;
  final String title;
  final String imageType;
  final String? cookingTime;
  final String? servings;
  final bool vegetarian;
  final bool vegan;
  final String? area;
  final String? category;
  final String image;
  final List<String>? tags;
  final List<String> instructions;
  final List<Ingredient> ingredients;
  final String? youtube;

  RecipeDetail({
    required this.id,
    required this.title,
    this.imageType = 'jpg',
    this.cookingTime,
    this.servings,
    this.vegetarian = false,
    this.vegan = false,
    this.area,
    this.category,
    required this.image,
    this.tags,
    required this.instructions,
    required this.ingredients,
    this.youtube,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    // Konvertiere MongoDB ObjectId zu String, falls notwendig
    final id = json['_id'] ?? json['id'];
    
    return RecipeDetail(
      id: id.toString(),
      title: json['title'],
      imageType: json['imageType'] ?? 'jpg',
      cookingTime: json['cookingTime'],
      servings: json['servings'],
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
      area: json['area'],
      category: json['category'],
      image: json['image'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'])
          : [],
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
              .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      youtube: json['youtube'],
    );
  }

  String get imageUrlLarge =>
      'https://img.spoonacular.com/recipes/$id-636x393.$imageType';

  String get imageUrlMedium =>
      'https://img.spoonacular.com/recipes/$id-480x360.$imageType';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': image,
    'servings': servings,
    'readyInMinutes': readyInMinutes,
    'summary': summaryHtml,
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    'extendedIngredients': extendedIngredients.map((e) => e.toJson()).toList(),
  };
}

class Ingredient {
  Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
  });

  final int id;
  final String name;
  final double amount;
  final String unit;

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
    id: j['id'] as int,
    name: j['name'] as String,
    amount: (j['amount'] as num).toDouble(),
    unit: j['unit'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
  };
}
