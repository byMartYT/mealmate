import 'package:flutter/material.dart';
import 'package:mealmate_new/features/home/home_recipe_item.dart';
import 'package:mealmate_new/layout/section.dart';
import 'package:mealmate_new/main.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

const double kboxHeight = 225;
const double kboxHeightSmall = 150;

class RecipeBox extends StatelessWidget {
  const RecipeBox({
    super.key,
    required this.recipes,
    required this.title,
    required this.repeat,
  });

  final List<RecipeSummary> recipes;
  final String title;
  final int repeat;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Section(
      title: title,
      children: [
        ...List.generate(repeat, (blockIndex) {
          final offset = blockIndex * 4;
          return Column(
            children: [
              if (blockIndex > 0) const SizedBox(height: kSpacing),
              SizedBox(
                height: kboxHeightSmall + kSpacing + kboxHeight,
                child: Row(
                  spacing: kSpacing,
                  children: [
                    // linke Spalte: kleines Item oben
                    _buildColumn(offset, smallOnTop: true),
                    // rechte Spalte: kleines Item unten
                    _buildColumn(offset + 2, smallOnTop: false),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Baut eine Spalte mit zwei Items, die je nach smallOnTop
  /// klein- bzw. groß-gerichtet angeordnet sind.
  Widget _buildColumn(int start, {required bool smallOnTop}) {
    final smallItem = SizedBox(
      height: kboxHeightSmall,
      child: HomeRecipeItem.fromMeal(recipes[start]),
    );
    final largeItem = SizedBox(
      height: kboxHeight,
      child: HomeRecipeItem.fromMeal(recipes[start + 1]),
    );

    return Expanded(
      child: Column(
        spacing: kSpacing,
        children: smallOnTop ? [smallItem, largeItem] : [largeItem, smallItem],
      ),
    );
  }
}
