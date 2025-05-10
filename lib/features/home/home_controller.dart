import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/spoonacular.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

class HomeState {
  final List<RecipeSummary> popular;
  final List<RecipeSummary> random;
  final bool isLoading;
  HomeState({
    this.popular = const [],
    this.random = const [],
    this.isLoading = false,
  });
}

class HomeController extends StateNotifier<HomeState> {
  final SpoonacularRepository _repo;
  HomeController(this._repo) : super(HomeState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = HomeState(
      popular: state.popular,
      random: state.random,
      isLoading: true,
    );
    final popular = await _repo.search(
      '',
      0,
      type: 'main course',
      limit: 10,
      sort: 'popularity',
    );
    final random = await _repo.search(
      '',
      0,
      type: 'main course',
      limit: 8,
      sort: 'random',
    );
    state = HomeState(popular: popular, random: random, isLoading: false);
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.watch(spoonRepoProvider)),
);
