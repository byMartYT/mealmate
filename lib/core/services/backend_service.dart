import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

final backendRepoProvider = Provider((_) => BackendRepository());

class BackendRepository {
  late final Dio _dio;

  BackendRepository() {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
    _dio = Dio(
      BaseOptions(
        baseUrl: backendUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Sucht nach Rezepten mit den angegebenen Parametern
  Future<List<Recipe>> search(
    String q,
    int offset, {
    int limit = 20,
    String category = '',
    String area = '',
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
        },
      );

      // Direkte Liste von Rezepten zurückgeben
      return (res.data as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Fehler beim Abrufen der Suchergebnisse: $e');
      return [];
    }
  }

  Future<List<Recipe>> getHighlights() async {
    try {
      final res = await _dio.get('/recipes/highlights');
      return (res.data as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Fehler beim Abrufen der Highlights: $e');
      return [];
    }
  }

  Future<List<Recipe>> getRandomRecipes({
    int limit = 5,
    String? category,
  }) async {
    try {
      final res = await _dio.get(
        '/recipes/random',
        queryParameters: {
          'limit': limit,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return (res.data as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Fehler beim Abrufen zufälliger Rezepte: $e');
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
        },
      );

      final recipes =
          (res.data['recipes'] as List)
              .map((json) => Recipe.fromJson(json))
              .toList();

      return {'total': res.data['total'], 'recipes': recipes};
    } catch (e) {
      print('Fehler bei der erweiterten Suche: $e');
      return {'total': 0, 'recipes': <Recipe>[]};
    }
  }

  /// Holt ein einzelnes Rezept anhand seiner ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final res = await _dio.get('/recipes/$id');
      return Recipe.fromJson(res.data);
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

  /// Lädt Base64-codierte Bilder hoch und gibt die URLs zurück
  Future<Map<String, dynamic>> uploadImages(List<String> base64Images) async {
    try {
      final res = await _dio.post(
        '/upload-images',
        data: {'images': base64Images},
      );

      return {
        'success': res.data['success'],
        'message': res.data['message'],
        'imageUrls': res.data['image_urls'] ?? [],
        'error': res.data['error'],
      };
    } catch (e) {
      print('Fehler beim Hochladen der Bilder: $e');
      return {
        'success': false,
        'message': 'Fehler beim Hochladen der Bilder',
        'imageUrls': <String>[],
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> detectIngredients(
    List<String> base64Images,
  ) async {
    try {
      final res = await _dio.post(
        '/detect-ingredients',
        data: {'images': base64Images},
      );

      if (res.data['success'] == true) {
        // Extrahiere die erkannten Zutaten
        return (res.data['ingredients'] as List)
            .map(
              (item) => {
                'name': item['name'],
                'amount': item['amount'],
                'unit': item['unit'],
              },
            )
            .toList();
      } else {
        print('Fehler bei der Zutatenerkennung: ${res.data['error']}');
        return [];
      }
    } catch (e) {
      print('Fehler beim Hochladen des Scans: $e');
      return [];
    }
  }

  Future<List<String>> getRecipeRecommendations(
    List<Map<String, dynamic>> ingredients,
  ) async {
    try {
      final res = await _dio.post('/recipes/generate/list', data: ingredients);

      // Konvertiere das Ergebnis in eine Liste von Strings
      return (res.data as List).cast<String>();
    } catch (e) {
      print('Error getting recipe recommendations: $e');
      return ['Failed to get recommendations: ${e.toString()}'];
    }
  }

  /// Generiert ein detailliertes Rezept basierend auf Titel und verfügbaren Zutaten
  Future<Map<String, dynamic>> getRecipeDetails(
    String recipeTitle,
    List<Map<String, dynamic>> ingredients,
  ) async {
    try {
      final res = await _dio.post(
        '/recipes/generate/details',
        data: {'recipe_title': recipeTitle, 'ingredients': ingredients},
      );

      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('Error generating recipe details: $e');
      return {
        'error': 'Failed to generate recipe details: ${e.toString()}',
        'title': recipeTitle,
        'ingredients': [],
        'instructions': [
          'Unable to generate recipe instructions. Please try again.',
        ],
      };
    }
  }
}
