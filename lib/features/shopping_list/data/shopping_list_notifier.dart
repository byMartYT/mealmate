// shopping_list_notifier.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingItem {
  ShoppingItem({required this.name, this.qty = 1, this.checked = false});
  String name;
  int qty;
  bool checked;

  Map<String, dynamic> toJson() => {'n': name, 'q': qty, 'c': checked};
  factory ShoppingItem.fromJson(Map<String, dynamic> j) =>
      ShoppingItem(name: j['n'], qty: j['q'], checked: j['c']);
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>((ref) {
      final prefs = ref.watch(prefsProvider);
      return ShoppingListNotifier(prefs);
    });

class ShoppingListNotifier extends StateNotifier<List<ShoppingItem>> {
  static const _key = 'shopping_list';
  final SharedPreferences _prefs;

  ShoppingListNotifier(this._prefs) : super(_load(_prefs));

  static List<ShoppingItem> _load(SharedPreferences p) {
    final raw = p.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(ShoppingItem.fromJson).toList();
  }

  void _persist() =>
      _prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));

  void add(String name) {
    state = [...state, ShoppingItem(name: name)];
    _persist();
  }

  void toggle(int index) {
    final item = state[index];
    state[index] = ShoppingItem(
      name: item.name,
      qty: item.qty,
      checked: !item.checked,
    );
    state = [...state];
    _persist();
  }
}
