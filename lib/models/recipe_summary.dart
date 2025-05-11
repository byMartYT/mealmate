class RecipeSummary {
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

  RecipeSummary({
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
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    // Konvertiere MongoDB ObjectId zu String, falls notwendig
    final id = json['_id'] ?? json['id'];

    return RecipeSummary(
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
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  // Getter für die Bildgröße wird nicht mehr benötigt,
  // da wir die vollständige URL vom Backend erhalten

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageType': imageType,
      'cookingTime': cookingTime,
      'servings': servings,
      'vegetarian': vegetarian,
      'vegan': vegan,
      'area': area,
      'category': category,
      'image': image,
      'tags': tags,
    };
  }
}
