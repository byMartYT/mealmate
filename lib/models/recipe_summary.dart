// lib/core/models/recipe_summary.dart
class RecipeSummary {
  RecipeSummary({required this.id, required this.title, required this.image});

  final int id;
  final String title;
  final String image;

  factory RecipeSummary.fromJson(Map<String, dynamic> j) => RecipeSummary(
    id: j['id'] as int,
    title: j['title'] as String,
    image: j['image'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'image': image};
}
