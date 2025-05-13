// filepath: /Users/martin/Dev/mealmate_new/lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/home/hero_carousel.dart';
import 'package:mealmate_new/features/home/home_controller.dart';
import 'package:mealmate_new/features/home/home_recipe_box.dart';
import 'package:mealmate_new/features/widgets/loading_screen.dart';
import 'package:mealmate_new/main.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);

    if (homeState.isLoading) {
      return const LoadingScreen(message: 'Loading recipes...');
    }

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        HeroCarousel(recipes: homeState.popular),
        const SizedBox(height: 20),
        Padding(
          padding: kPadding.copyWith(bottom: 20),
          child: Column(
            spacing: 40,
            children: [
              RecipeBox(
                recipes: homeState.random,
                title: 'Random recipes',
                repeat: 2,
              ),
              RecipeBox(
                recipes: homeState.veggie,
                title: 'Vegetarian recipes',
                repeat: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
