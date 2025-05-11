import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

final backendRepoProvider = Provider((_) => BackendRepository());

/// Repository für den Zugriff auf das eigene Backend
class BackendRepository {
  // Hier solltest du die URL deines Backends anpassen
  // Für Emulatoren: Android = 10.0.2.2, iOS = localhost
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Sucht nach Rezepten mit den angegebenen Parametern
  Future<List<RecipeSummary>> search(
    String q,
    int offset, {
    int limit = 20,
    String category = '',
    String area = '',
    String sort = '',
    String sortDirection = 'asc',
  }) async {
    try {
      // Verwende die in Backend implementierten Parameter
      final res = await _dio.get(
        '/recipes',
        queryParameters: {
          'search': q,
          'skip': offset,
          'limit': limit,
          if (category.isNotEmpty) 'category': category,
          if (area.isNotEmpty) 'area': area,
          if (sort.isNotEmpty) 'sort_by': sort,
          'sort_dir': sortDirection,
        },
      );

      // Direkte Liste von Rezepten zurückgeben
      return (res.data as List)
          .map((json) => RecipeSummary.fromJson(json))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Suchergebnisse: $e');
      return [];
    }
  }

  Future<List<RecipeSummary>> getHighlights() async {
    try {
      final res = await _dio.get('/recipes/highlights');
      return (res.data as List)
          .map((json) => RecipeSummary.fromJson(json))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Highlights: $e');
      return [];
    }
  }

  /// Detaillierte Suche mit zusätzlichen Parametern
  Future<Map<String, dynamic>> advancedSearch(
    String q, {
    int skip = 0,
    int limit = 20,
    String category = '',
    String area = '',
    String sort = '',
    String sortDirection = 'asc',
  }) async {
    try {
      final res = await _dio.get(
        '/search',
        queryParameters: {
          'q': q,
          'skip': skip,
          'limit': limit,
          if (category.isNotEmpty) 'category': category,
          if (area.isNotEmpty) 'area': area,
          if (sort.isNotEmpty) 'sort_by': sort,
          'sort_dir': sortDirection,
        },
      );

      final recipes =
          (res.data['recipes'] as List)
              .map((json) => RecipeSummary.fromJson(json))
              .toList();

      return {'total': res.data['total'], 'recipes': recipes};
    } catch (e) {
      print('Fehler bei der erweiterten Suche: $e');
      return {'total': 0, 'recipes': <RecipeSummary>[]};
    }
  }

  /// Holt ein einzelnes Rezept anhand seiner ID
  Future<RecipeSummary?> getRecipeById(String id) async {
    try {
      final res = await _dio.get('/recipes/$id');
      return RecipeSummary.fromJson(res.data);
    } catch (e) {
      print('Fehler beim Abrufen des Rezepts mit ID $id: $e');
      return null;
    }
  }

  /// Holt alle verfügbaren Kategorien
  Future<List<String>> getCategories() async {
    try {
      final res = await _dio.get('/categories');
      return (res.data['categories'] as List).cast<String>();
    } catch (e) {
      print('Fehler beim Abrufen der Kategorien: $e');
      return [];
    }
  }

  /// Holt alle verfügbaren Herkunftsregionen
  Future<List<String>> getAreas() async {
    try {
      final res = await _dio.get('/areas');
      return (res.data['areas'] as List).cast<String>();
    } catch (e) {
      print('Fehler beim Abrufen der Herkunftsregionen: $e');
      return [];
    }
  }
}
