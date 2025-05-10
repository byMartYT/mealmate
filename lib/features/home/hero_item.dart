import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

const borderRadius = BorderRadius.all(Radius.circular(20));

class HeroItem extends StatelessWidget {
  const HeroItem({super.key, required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap: () => {context.push('/home/detail', extra: recipe.id)},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(46),
                blurRadius: 35,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              // if (recipe.strTags != null && recipe.strTags!.isNotEmpty)
              //   Expanded(child: TagList(tags: recipe.strTags!)),
            ],
          ),
        ),
      ),
    );
  }
}
