import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';

/// Provider für die zwischengespeicherten Kategorien
final categoriesProvider = StateProvider<List<String>>((ref) => []);

/// Provider für das Laden der Kategorien
final categoriesFutureProvider = FutureProvider<List<String>>((ref) async {
  // Lade die Kategorien vom Backend
  final repo = ref.watch(backendRepoProvider);
  final categories = await repo.getCategories();
  // Aktualisiere den State-Provider
  ref.read(categoriesProvider.notifier).state = categories;
  return categories;
});
