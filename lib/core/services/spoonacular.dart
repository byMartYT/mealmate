import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/models/recipe_detail.dart';
import 'package:mealmate_new/models/recipe_summary.dart';

final spoonRepoProvider = Provider((_) => SpoonacularRepository());

class SpoonacularRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.spoonacular.com'));

  String get _key => dotenv.env['SPOON_KEY']!;

  Future<List<RecipeSummary>> search(
    String q,
    int offset, {
    int limit = 20,
    String type = '',
    String diet = '',
    String sort = '',
    String sortDirection = 'asc',
  }) async {
    try {
      final res = await _dio.get(
        '/recipes/complexSearch',
        queryParameters: {
          'query': q,
          'number': limit,
          'offset': offset,
          'apiKey': _key,
          'addRecipeInformation': true,
          'type': type,
          'diet': diet,
          'sort': sort,
          'sortDirection': sortDirection,
        },
      );
      return (res.data['results'] as List)
          .map((j) => RecipeSummary.fromJson(j))
          .toList();
    } catch (e) {
      print('Error fetching search results: $e');
      return [];
    }
  }

  Future<List<RecipeDetail>> bulk(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final res = await _dio.get(
        '/recipes/informationBulk',
        queryParameters: {'ids': ids.join(','), 'apiKey': _key},
      );
      return (res.data as List).map((j) => RecipeDetail.fromJson(j)).toList();
    } catch (e) {
      print('Error fetching bulk recipe details: $e');
      return [];
    }
  }
}
