import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/widgets/meta_list.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

const borderRadius = BorderRadius.all(Radius.circular(20));

class HeroItem extends StatelessWidget {
  const HeroItem({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap:
          () => {
            context.push(
              '${GoRouterState.of(context).matchedLocation}/detail',
              extra: recipe.id,
            ),
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.primaryContainer,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              MetaList([
                Meta(text: recipe.cookingTime, icon: Icons.timer_outlined),
                Meta(text: recipe.servings, icon: Icons.room_service_outlined),
              ], color: Theme.of(context).colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
