import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/home/hero_item.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

const double kHeroHeight = 0.55;
const double kItemHeight = 100;

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.recipes});

  final List<RecipeSummary> recipes;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Prefetch das erste Bild
    if (widget.recipes.isNotEmpty) {
      precacheImage(NetworkImage(widget.recipes[0].image), context);
    }
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Prefetch das nächste Bild, wenn sich die Rezepte ändern
    if (_current < widget.recipes.length - 1) {
      precacheImage(NetworkImage(widget.recipes[_current + 1].image), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * kHeroHeight,
        child: const Center(child: Text('No recipes available')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Carousel
        Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: kItemHeight / 2),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;

                  if (details.primaryVelocity! < 0) {
                    // Swipe nach links
                    if (_current < widget.recipes.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  } else if (details.primaryVelocity! > 0) {
                    // Swipe nach rechts
                    if (_current > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: InkWell(
                    onTap: () {
                      context.push(
                        '/home/detail',
                        extra: widget.recipes[_current].id,
                      );
                    },
                    child: Image.network(
                      widget.recipes[_current].image,
                      key: ValueKey<int>(_current),
                      height: MediaQuery.of(context).size.height * kHeroHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: kItemHeight,
              child: PageView.builder(
                clipBehavior: Clip.none,
                controller: _pageController,
                itemCount: widget.recipes.length,
                onPageChanged: (index) {
                  setState(() {
                    _current = index;

                    // Prefetch das nächste Bild
                    if (_current < widget.recipes.length - 1) {
                      precacheImage(
                        NetworkImage(widget.recipes[_current + 1].image),
                        context,
                      );
                    }
                  });
                },
                itemBuilder: (context, i) {
                  final r = widget.recipes[i];
                  return HeroItem(recipe: r);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.recipes.length, (i) {
            final isActive = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
