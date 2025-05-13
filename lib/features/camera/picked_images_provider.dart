import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider für die ausgewählten Bilder (als Base64-Strings)
final pickedImagesProvider =
    StateNotifierProvider<PickedImagesNotifier, List<String>>((ref) {
      return PickedImagesNotifier();
    });

/// Notifier für die ausgewählten Bilder
class PickedImagesNotifier extends StateNotifier<List<String>> {
  PickedImagesNotifier() : super([]);

  /// Ausgewählte Bilder hinzufügen
  void addImages(List<String> base64Images) {
    state = [...state, ...base64Images];
  }

  /// Alle Bilder löschen
  void clearImages() {
    state = [];
  }

  /// Ein einzelnes Bild löschen
  void removeImage(int index) {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState.removeAt(index);
      state = newState;
    }
  }

  /// Bilder ersetzen
  void replaceImages(List<String> base64Images) {
    state = [...base64Images];
  }
}
