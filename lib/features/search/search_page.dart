import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/search/search_item.dart';
import 'package:mealmate_new/main.dart';
import 'search_controller.dart';

enum FilterOption { none /*, vegetarian, glutenFree, ...*/ }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  FilterOption _filter = FilterOption.none;

  @override
  void initState() {
    super.initState();
    // Trigger initial empty-query fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchControllerProvider(_query).notifier).fetchNext();
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
    final choice = await showModalBottomSheet<FilterOption>(
      context: context,
      builder: (_) {
        return ListView(
          children:
              FilterOption.values.map((opt) {
                return RadioListTile<FilterOption>(
                  title: Text(opt.name),
                  value: opt,
                  groupValue: _filter,
                  onChanged: (v) => Navigator.pop(context, v),
                );
              }).toList(),
        );
      },
    );
    if (choice != null && choice != _filter) {
      setState(() => _filter = choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider(_query));
    final recipes = state.items;
    print(state.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: kToolbarHeight - 8,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search recipes...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
            onSubmitted: (value) {
              setState(() {
                _query = value;
              });
              // Reset and fetch new query
              ref.refresh(searchControllerProvider(value));
              ref.read(searchControllerProvider(value).notifier).fetchNext();
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
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                padding: kPadding,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
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
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
    );
  }
}
