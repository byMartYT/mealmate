import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/spoonacular.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class SearchState {
  final List<RecipeSummary> items;
  final bool isLoading;
  final bool hasMore;
  final int page;

  const SearchState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
  });

  SearchState copyWith({
    List<RecipeSummary>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) => SearchState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
  );
}

class SearchController extends StateNotifier<SearchState> {
  final SpoonacularRepository _repo;
  final String _query;
  static const _pageSize = 20;
  String? _sort;
  String _sortDir = 'asc';

  SearchController(this._repo, this._query) : super(const SearchState()) {
    _fetch();
  }

  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;
    print('123');
    await _fetch();
  }

  /// Change the sorting parameters and reload from page 1
  Future<void> changeSort(String sort, String direction) async {
    // Reset state and paging
    state = const SearchState();
    _sort = sort;
    _sortDir = direction;
    await _fetch();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;
    final data = await _repo.search(
      _query,
      (nextPage - 1) * _pageSize,
      sort: _sort ?? 'asc',
      sortDirection: _sortDir,
    );
    state = state.copyWith(
      items: [...state.items, ...data],
      isLoading: false,
      hasMore: data.length == _pageSize,
      page: nextPage,
    );
  }
}

final searchControllerProvider =
    StateNotifierProvider.family<SearchController, SearchState, String>((
      ref,
      q,
    ) {
      return SearchController(ref.watch(spoonRepoProvider), q);
    });
