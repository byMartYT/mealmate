class RecipeSummary {
  final int id;
  final String title;
  final String imageType;
  final int readyInMinutes;
  final int servings;
  final bool vegetarian;
  final bool vegan;

  RecipeSummary({
    required this.id,
    required this.title,
    required this.imageType,
    required this.readyInMinutes,
    required this.servings,
    required this.vegetarian,
    required this.vegan,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id'],
      title: json['title'],
      imageType: json['imageType'] ?? 'jpg',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
    );
  }

  String get imageUrlLarge =>
      'https://img.spoonacular.com/recipes/$id-636x393.$imageType';

  String get imageUrlMedium =>
      'https://img.spoonacular.com/recipes/$id-480x360.$imageType';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageType': imageType,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'vegetarian': vegetarian,
      'vegan': vegan,
    };
  }
}
