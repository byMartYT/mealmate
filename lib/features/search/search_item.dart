import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class SearchItem extends StatelessWidget {
  const SearchItem(this.recipe, {super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => context.push(
            '${GoRouterState.of(context).matchedLocation}/detail',
            extra: recipe.id,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quadratisches Bild mit AspectRatio
          AspectRatio(
            aspectRatio: 1.0, // Quadratisches Verhältnis
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(recipe.image, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 8), // Konsistenter Abstand
          // Titel mit fester Höhe für 2 Zeilen
          SizedBox(
            height: 38, // Leicht reduzierte Höhe für 2 Zeilen Text
            child: Text(
              recipe.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Etwas kleinere Schrift
                height: 1.2, // Kompaktere Zeilenhöhe
              ),
            ),
          ),
          // Kochzeit mit minimalem Abstand
          Padding(
            padding: const EdgeInsets.only(top: 2), // Reduzierten Abstand
            child: Text(
              recipe.cookingTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11, // Etwas kleinere Schrift
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1.0, // Minimale Zeilenhöhe
              ),
            ),
          ),
        ],
      ),
    );
  }
}
