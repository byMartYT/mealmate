import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

const kPadding = 12.0;

class HomeRecipeItem extends StatelessWidget {
  const HomeRecipeItem({
    super.key,
    required this.title,
    required this.id,
    required this.image,
  });

  factory HomeRecipeItem.fromMeal(Recipe recipe) {
    return HomeRecipeItem(
      title: recipe.title,
      id: recipe.id,
      image: recipe.image,
    );
  }

  final String title;
  final String id;
  final String image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        GoRouter.of(context).push(
          '${GoRouterState.of(context).matchedLocation}/detail',
          extra: id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kPadding),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kPadding),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(kPadding),
                  ),
                  gradient: LinearGradient(
                    end: Alignment.topCenter,
                    begin: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(224, 0, 0, 0),
                      const Color.fromARGB(0, 0, 0, 0),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(kPadding),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
