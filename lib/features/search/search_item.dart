import 'package:flutter/material.dart';
import 'package:mealmate_new/main.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class SearchItem extends StatelessWidget {
  const SearchItem(this.recipe, {super.key});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kSpacing,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                height: 180,
                width: double.infinity,
                recipe.imageUrlMedium,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            recipe.readyInMinutes == 0
                ? 'Unknown time'
                : '${recipe.readyInMinutes} min',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Color.fromARGB(153, 0, 0, 0)),
          ),
        ],
      ),
    );
  }
}
