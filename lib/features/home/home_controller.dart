import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
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
  final BackendRepository _repo;
  HomeController(this._repo) : super(HomeState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = HomeState(
      popular: state.popular,
      random: state.random,
      isLoading: true,
    );
    final popular = await _repo.getHighlights();
    final random = await _repo.getRandomRecipes(limit: 8);
    state = HomeState(popular: popular, random: random, isLoading: false);
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.watch(backendRepoProvider)),
);
