import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class SearchState {
  final List<Recipe> items;
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
    List<Recipe>? items,
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
  final BackendRepository _repo;
  final String _query;
  static const _pageSize = 20;
  String? _category;
  String? _area;

  SearchController(this._repo, this._query) : super(const SearchState());

  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;
    await _fetch();
  }

  /// Ändere die Filterkategorien und lade von Seite 1 neu
  Future<void> changeFilter({String? category, String? area}) async {
    // Zurücksetzen des Zustands und der Seitenzahlen
    state = const SearchState();
    _category = category;
    _area = area;
    await _fetch();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;

    try {
      final data = await _repo.search(
        _query,
        (nextPage - 1) * _pageSize,
        limit: _pageSize,
        category: _category ?? '',
        area: _area ?? '',
      );

      state = state.copyWith(
        items: [...state.items, ...data],
        isLoading: false,
        hasMore: data.length == _pageSize,
        page: nextPage,
      );
    } catch (e) {
      print('Fehler beim Laden der Rezepte: $e');
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

final searchControllerProvider =
    StateNotifierProvider.family<SearchController, SearchState, String>((
      ref,
      q,
    ) {
      return SearchController(ref.watch(backendRepoProvider), q);
    });
