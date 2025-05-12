class DetectedIngredient {
  final String name;
  final String? amount;
  final String? unit;

  DetectedIngredient({required this.name, this.amount, this.unit});

  // Creates an instance from a JSON object
  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      name: json['name'] ?? '',
      amount: json['amount'],
      unit: json['unit'],
    );
  }

  // Konvertiert zu einem JSON-Objekt
  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount, 'unit': unit};
  }

  // Konvertierung zu einer Ingredient-Instanz für die Einkaufsliste
  Map<String, dynamic> toShoppingItem() {
    String measure = '';

    // Wenn Menge und Einheit vorhanden sind, kombiniere sie
    if (amount != null && unit != null) {
      measure = '$amount $unit';
    } else if (amount != null) {
      measure = amount!;
    } else if (unit != null) {
      measure = unit!;
    }

    return {'name': name, 'measure': measure.trim()};
  }

  // Einfache Textdarstellung für die Anzeige
  String getDisplayText() {
    if (amount != null && unit != null) {
      return '$name ($amount $unit)';
    } else if (amount != null) {
      return '$name ($amount)';
    } else if (unit != null) {
      return '$name ($unit)';
    } else {
      return name;
    }
  }
}
