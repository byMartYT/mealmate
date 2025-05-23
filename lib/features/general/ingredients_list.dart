import 'package:flutter/material.dart';
import 'package:mealmate_new/models/ingredient.dart';

class IngredientsList extends StatelessWidget {
  const IngredientsList(this.ingredients, {super.key});

  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
        for (var ingredient in ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(ingredient.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient.measure,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
