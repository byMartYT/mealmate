import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/features/search/search_item.dart';
import 'package:mealmate_new/features/search/search_providers.dart';
import 'package:mealmate_new/features/widgets/error_screen.dart';
import 'package:mealmate_new/features/widgets/loading_screen.dart';
import 'package:mealmate_new/main.dart';
import 'search_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Trigger initial empty-query fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lade die Kategorien beim initialen Laden der Seite
      ref.read(categoriesFutureProvider);

      // Initialisiere den Controller und wende ggf. Kategoriefilter an
      final controller = ref.read(searchControllerProvider(_query).notifier);
      if (_selectedCategory != null) {
        controller.changeFilter(category: _selectedCategory);
      } else {
        controller.fetchNext();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (pos >= max - 200) {
      ref.read(searchControllerProvider(_query).notifier).fetchNext();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showFilterDialog() async {
    // Verwende die zwischengespeicherten Kategorien oder lade sie, wenn sie noch nicht geladen wurden
    List<String> categories = ref.read(categoriesProvider);

    // Wenn die Kategorien noch nicht geladen wurden
    if (categories.isEmpty) {
      try {
        // Zeige einen Ladestatus nur wenn wir explizit Kategorien laden müssen
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LoadingScreen(message: 'Loading categories...'),
        );

        // Lade die Kategorien vom Backend
        categories = await ref.read(backendRepoProvider).getCategories();
        ref.read(categoriesProvider.notifier).state = categories;
      } finally {
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    if (!context.mounted) return;

    final category = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Alle Kategorien',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => Navigator.pop(context, null),
              trailing:
                  _selectedCategory == null
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category),
                    onTap: () => Navigator.pop(context, category),
                    trailing:
                        _selectedCategory == category
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });

      final controller = ref.read(searchControllerProvider(_query).notifier);
      controller.changeFilter(category: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider(_query));
    final recipes = state.items;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: kToolbarHeight - 8,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              suffix:
                  _selectedCategory != null
                      ? Chip(
                        label: Text(
                          _selectedCategory!,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onDeleted: () {
                          setState(() => _selectedCategory = null);
                          final controller = ref.read(
                            searchControllerProvider(_query).notifier,
                          );
                          controller.changeFilter(category: null);
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                      : null,
            ),
            onSubmitted: (value) {
              // Speichere den aktuellen Filter
              final currentCategory = _selectedCategory;

              setState(() {
                _query = value;
              });

              ref.invalidate(searchControllerProvider(value));

              // Explizit nur einen Fetch mit korrektem Filter ausführen
              final controller = ref.read(
                searchControllerProvider(value).notifier,
              );
              controller.changeFilter(category: currentCategory);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body:
          state.isLoading && recipes.isEmpty
              ? const LoadingScreen(message: 'Searching recipes...')
              : recipes.isEmpty
              ? ErrorScreen.general(
                message: 'Keine Rezepte gefunden',
                withScaffold: false,
              )
              : GridView.builder(
                padding: kPadding,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.74,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                controller: _scrollController,
                itemCount: recipes.length + (state.hasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i < recipes.length) {
                    return SearchItem(recipes[i]);
                  }
                  // loading indicator at the bottom
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LoadingScreen(message: 'Loading more...'),
                  );
                },
              ),
    );
  }
}
