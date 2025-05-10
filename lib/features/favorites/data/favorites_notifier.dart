// favourites_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>((
  ref,
) {
  final prefs = ref.watch(prefsProvider);
  return FavoritesNotifier(prefs);
});

class FavoritesNotifier extends StateNotifier<Set<int>> {
  static const _key = 'favourites';
  final SharedPreferences _prefs;
  FavoritesNotifier(this._prefs)
    : super(_prefs.getStringList(_key)?.map(int.parse).toSet() ?? {});

  void toggle(int id) {
    final newSet = {...state};
    newSet.contains(id) ? newSet.remove(id) : newSet.add(id);
    state = newSet;
    _prefs.setStringList(_key, newSet.map((e) => e.toString()).toList());
  }
}
