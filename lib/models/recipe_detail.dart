// lib/core/models/recipe_detail.dart
class RecipeDetail {
  RecipeDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.servings,
    required this.readyInMinutes,
    required this.summaryHtml,
    required this.imageType,
    required this.extendedIngredients,
    this.sourceName,
    this.sourceUrl,
  });

  final int id;
  final String title;
  final String image;
  final int servings;
  final String imageType;
  final int readyInMinutes;

  final String summaryHtml; // contains <b> tags
  final List<Ingredient> extendedIngredients;

  // optional meta
  final String? sourceName;
  final String? sourceUrl;

  factory RecipeDetail.fromJson(Map<String, dynamic> j) => RecipeDetail(
    id: j['id'] as int,
    title: j['title'] as String,
    image: j['image'] as String,
    servings: j['servings'] as int,
    imageType: j['imageType'] ?? 'jpg',
    readyInMinutes: j['readyInMinutes'] as int,
    summaryHtml: j['summary'] as String,
    sourceName: j['sourceName'] as String?,
    sourceUrl: j['sourceUrl'] as String?,
    extendedIngredients:
        (j['extendedIngredients'] as List<dynamic>)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

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
