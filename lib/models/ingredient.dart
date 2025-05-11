class Ingredient {
  final String name;
  final String measure;

  Ingredient({required this.name, required this.measure});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(name: json['name'], measure: json['measure']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'measure': measure};
  }
}
