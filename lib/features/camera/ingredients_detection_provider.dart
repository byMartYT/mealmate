import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/models/detected_ingredient.dart';

// Status der Erkennung
enum DetectionStatus { initial, loading, success, error }

// Zustandsklasse für die Zutatenerkennung
class IngredientsDetectionState {
  final List<DetectedIngredient> ingredients;
  final DetectionStatus status;
  final String? errorMessage;
  final bool isProcessing;

  IngredientsDetectionState({
    this.ingredients = const [],
    this.status = DetectionStatus.initial,
    this.errorMessage,
    this.isProcessing = false,
  });

  // Erstellt eine Kopie mit aktualisierten Werten
  IngredientsDetectionState copyWith({
    List<DetectedIngredient>? ingredients,
    DetectionStatus? status,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return IngredientsDetectionState(
      ingredients: ingredients ?? this.ingredients,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

// Provider für die Zutatenerkennung
final ingredientsDetectionProvider = StateNotifierProvider<
  IngredientsDetectionNotifier,
  IngredientsDetectionState
>((ref) {
  final backendRepo = ref.watch(backendRepoProvider);
  return IngredientsDetectionNotifier(backendRepo);
});

class IngredientsDetectionNotifier
    extends StateNotifier<IngredientsDetectionState> {
  final BackendRepository _backendRepo;

  IngredientsDetectionNotifier(this._backendRepo)
    : super(IngredientsDetectionState());

  // Erkennt Zutaten aus einer Liste von Base64-Bildern
  Future<void> detectIngredientsFromImages(List<String> base64Images) async {
    // Status auf "laden" setzen
    state = state.copyWith(
      status: DetectionStatus.loading,
      isProcessing: true,
      errorMessage: null,
    );

    try {
      // Anfrage an den Backend-Service
      final ingredientsData = await _backendRepo.detectIngredients(
        base64Images,
      );

      print(ingredientsData);

      // Wenn keine Zutaten gefunden wurden
      if (ingredientsData.isEmpty) {
        state = state.copyWith(
          status: DetectionStatus.error,
          errorMessage:
              'Keine Zutaten gefunden. Bitte versuche es mit einem klareren Bild.',
          isProcessing: false,
        );
        return;
      }

      // Zutaten in das richtige Format konvertieren
      final ingredients =
          ingredientsData
              .map((data) => DetectedIngredient.fromJson(data))
              .toList();

      // Status aktualisieren
      state = state.copyWith(
        ingredients: ingredients,
        status: DetectionStatus.success,
        isProcessing: false,
      );
    } catch (e) {
      // Fehlerbehandlung
      state = state.copyWith(
        status: DetectionStatus.error,
        errorMessage: 'Fehler bei der Zutatenerkennung: ${e.toString()}',
        isProcessing: false,
      );
    }
  }

  // Löscht eine Zutat aus der Liste
  void removeIngredient(int index) {
    if (index < 0 || index >= state.ingredients.length) return;

    final updatedIngredients = List<DetectedIngredient>.from(state.ingredients);
    updatedIngredients.removeAt(index);

    state = state.copyWith(ingredients: updatedIngredients);
  }

  // Fügt eine neue Zutat zur Liste hinzu
  void addIngredient(DetectedIngredient ingredient) {
    final updatedIngredients = List<DetectedIngredient>.from(state.ingredients);
    updatedIngredients.add(ingredient);
    state = state.copyWith(ingredients: updatedIngredients);
  }

  // Aktualisiert eine Zutat
  void updateIngredient(int index, DetectedIngredient updatedIngredient) {
    if (index < 0 || index >= state.ingredients.length) return;

    final updatedIngredients = List<DetectedIngredient>.from(state.ingredients);
    updatedIngredients[index] = updatedIngredient;

    state = state.copyWith(ingredients: updatedIngredients);
  }

  // Setzt den Zustand zurück
  void reset() {
    state = IngredientsDetectionState();
  }

  // Sendet die Zutaten ans Backend und erhält Rezeptvorschläge
  Future<List<String>> getRecipeRecommendations() async {
    try {
      // Status auf "laden" setzen
      state = state.copyWith(isProcessing: true);

      // Zutaten in das richtige Format konvertieren
      final ingredientsData =
          state.ingredients.map((ing) => ing.toJson()).toList();

      // Logger-Ausgabe für Debugging
      print('Sending ingredients to backend: $ingredientsData');

      // API-Aufruf zum Backend
      final recommendations = await _backendRepo.getRecipeRecommendations(
        ingredientsData,
      );

      // Status zurücksetzen
      state = state.copyWith(isProcessing: false);

      return recommendations;
    } catch (e) {
      // Fehlerbehandlung
      state = state.copyWith(
        status: DetectionStatus.error,
        errorMessage: 'Error getting recipe recommendations: ${e.toString()}',
        isProcessing: false,
      );
      return [];
    }
  }
}
