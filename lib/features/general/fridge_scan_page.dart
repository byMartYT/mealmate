import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/core/services/backend_service.dart';
import 'package:mealmate_new/features/camera/camera_page.dart';
import 'package:mealmate_new/models/ingredient.dart';

/// Provider für erkannte Zutaten
final detectedIngredientsProvider =
    StateNotifierProvider<DetectedIngredientsNotifier, List<Ingredient>>((ref) {
      return DetectedIngredientsNotifier();
    });

/// Notifier für die Verwaltung erkannter Zutaten
class DetectedIngredientsNotifier extends StateNotifier<List<Ingredient>> {
  DetectedIngredientsNotifier() : super([]);

  void setIngredients(List<Ingredient> ingredients) {
    state = ingredients;
  }

  void addIngredient(Ingredient ingredient) {
    state = [...state, ingredient];
  }

  void removeIngredient(int index) {
    final ingredients = [...state];
    ingredients.removeAt(index);
    state = ingredients;
  }

  void updateIngredient(int index, Ingredient ingredient) {
    final ingredients = [...state];
    ingredients[index] = ingredient;
    state = ingredients;
  }

  void clearIngredients() {
    state = [];
  }
}

/// Provider für den Zustand des Kühlschrankscans
final fridgeScanStateProvider =
    StateNotifierProvider<FridgeScanStateNotifier, FridgeScanState>((ref) {
      return FridgeScanStateNotifier();
    });

/// Zustand für den Kühlschrankscan
class FridgeScanState {
  final bool isAnalyzing;
  final bool hasError;
  final String? errorMessage;
  final List<String>? fridgeImages; // Base64-codierte Bilder vom Kühlschrank

  FridgeScanState({
    this.isAnalyzing = false,
    this.hasError = false,
    this.errorMessage,
    this.fridgeImages,
  });

  FridgeScanState copyWith({
    bool? isAnalyzing,
    bool? hasError,
    String? errorMessage,
    List<String>? fridgeImages,
  }) {
    return FridgeScanState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      fridgeImages: fridgeImages ?? this.fridgeImages,
    );
  }
}

/// Notifier für die Verwaltung des Kühlschrankscan-Zustands
class FridgeScanStateNotifier extends StateNotifier<FridgeScanState> {
  FridgeScanStateNotifier() : super(FridgeScanState());

  void setAnalyzing(bool isAnalyzing) {
    state = state.copyWith(isAnalyzing: isAnalyzing);
  }

  void setError(String errorMessage) {
    state = state.copyWith(hasError: true, errorMessage: errorMessage);
  }

  void clearError() {
    state = state.copyWith(hasError: false, errorMessage: null);
  }

  void setFridgeImages(List<String> images) {
    state = state.copyWith(fridgeImages: images);
  }

  void reset() {
    state = FridgeScanState();
  }
}

/// Page zum Scannen des Kühlschranks und Erkennen von Zutaten
class FridgeScanPage extends ConsumerStatefulWidget {
  const FridgeScanPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FridgeScanPage> createState() => _FridgeScanPageState();
}

class _FridgeScanPageState extends ConsumerState<FridgeScanPage> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribeToPickedImages();
  }

  void _subscribeToPickedImages() {
    // Beim Zurückkehren von der Kamera-Seite die ausgewählten Bilder abrufen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final images = ref.read(pickedImagesProvider);
      if (images.isNotEmpty) {
        // Bilder im Provider speichern
        ref.read(fridgeScanStateProvider.notifier).setFridgeImages(images);
        // Bilder im Kamera-Provider zurücksetzen
        ref.read(pickedImagesProvider.notifier).clearImages();

        // Automatisch die Analyse starten
        _analyzeImages(images);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _navigateToCamera() {
    // Zur Kamera-Seite navigieren
    context.push('/camera');
  }

  void _analyzeImages(List<String> images) async {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte zuerst ein Bild des Kühlschranks aufnehmen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Status auf "Analysiere" setzen
    ref.read(fridgeScanStateProvider.notifier).setAnalyzing(true);
    final backend = ref.read(backendRepoProvider);

    try {
      // Bilder zum Backend hochladen
      final uploadResult = await backend.uploadImages(images);

      if (uploadResult['success'] != true) {
        throw Exception(
          'Fehler beim Hochladen der Bilder: ${uploadResult['error']}',
        );
      }

      // Bild-URLs vom Upload-Ergebnis holen
      final imageUrls = List<String>.from(uploadResult['imageUrls']);

      if (imageUrls.isEmpty) {
        throw Exception('Keine Bilder konnten hochgeladen werden');
      }

      // Zutaten mit dem LLM erkennen
      final detectResult = await backend.detectIngredients(imageUrls);

      if (detectResult['success'] != true) {
        throw Exception(
          'Fehler bei der Zutatenerkennung: ${detectResult['error']}',
        );
      }

      // Zutaten aus der Antwort extrahieren und in Ingredient-Objekte umwandeln
      final ingredientsList = List<Map<String, dynamic>>.from(
        detectResult['ingredients'],
      );
      final ingredients =
          ingredientsList.map((ingredientMap) {
            return Ingredient(
              name: ingredientMap['name'],
              measure: ingredientMap['measure'],
            );
          }).toList();

      // Erkannte Zutaten im Provider speichern
      ref
          .read(detectedIngredientsProvider.notifier)
          .setIngredients(ingredients);

      // Analyse abgeschlossen
      ref.read(fridgeScanStateProvider.notifier).setAnalyzing(false);

      // Erfolg anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ingredients.length} Zutaten im Kühlschrank erkannt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fehler im Zustand speichern und anzeigen
      ref.read(fridgeScanStateProvider.notifier).setError(e.toString());
      ref.read(fridgeScanStateProvider.notifier).setAnalyzing(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler bei der Analyse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addIngredient() {
    if (_nameController.text.isEmpty) return;

    // Kombiniere Menge und Einheit zu einer Maßangabe
    String measure = '';
    if (_amountController.text.isNotEmpty) {
      measure = _amountController.text;

      if (_unitController.text.isNotEmpty) {
        measure += ' ' + _unitController.text;
      }
    } else if (_unitController.text.isNotEmpty) {
      measure = _unitController.text;
    }

    // Zutat zum Provider hinzufügen
    ref
        .read(detectedIngredientsProvider.notifier)
        .addIngredient(
          Ingredient(
            name: _nameController.text,
            measure: measure.isEmpty ? 'nach Geschmack' : measure,
          ),
        );

    // Textfelder leeren
    _nameController.clear();
    _amountController.clear();
    _unitController.clear();
  }

  void _getRecipeSuggestions() async {
    final ingredients = ref.read(detectedIngredientsProvider);

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Es wurden keine Zutaten erkannt. Bitte scannen Sie Ihren Kühlschrank erneut.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rezeptvorschläge werden generiert...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Hier würde die Anfrage an das Backend für Rezeptvorschläge erfolgen
    // Im Moment navigieren wir einfach zurück zur Home-Seite

    // Zur Home-Seite navigieren
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(fridgeScanStateProvider);
    final ingredients = ref.watch(detectedIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kühlschrank scannen'),
        actions: [
          if (ingredients.isNotEmpty)
            IconButton(
              onPressed: _getRecipeSuggestions,
              icon: const Icon(Icons.restaurant_menu),
              tooltip: 'Rezeptvorschläge anzeigen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Erklärungstext
              const Text(
                'Mache ein Foto deines Kühlschranks, um verfügbare Zutaten zu erkennen.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // Bilder-Sektion
              _buildImageSection(scanState.fridgeImages ?? []),

              const SizedBox(height: 20),

              // Button zum Analysieren der Bilder (nur anzeigen, wenn Bilder vorhanden sind)
              if ((scanState.fridgeImages?.isNotEmpty ?? false) &&
                  !scanState.isAnalyzing)
                ElevatedButton.icon(
                  onPressed: () => _analyzeImages(scanState.fridgeImages!),
                  icon: const Icon(Icons.search),
                  label: const Text('Zutaten erkennen'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),

              // Ladeanzeige während der Analyse
              if (scanState.isAnalyzing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Kühlschrank wird analysiert...'),
                    ],
                  ),
                ),

              if (scanState.hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fehler bei der Analyse:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(scanState.errorMessage ?? 'Unbekannter Fehler'),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Erkannte Zutaten anzeigen
              if (ingredients.isNotEmpty) ...[
                const Text(
                  'Erkannte Zutaten',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Liste der erkannten Zutaten
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = ingredients[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.measure),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit-Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              // Hier könnte ein Dialog zum Bearbeiten der Zutat angezeigt werden
                              _showEditIngredientDialog(
                                context,
                                index,
                                ingredient,
                              );
                            },
                          ),
                          // Delete-Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              ref
                                  .read(detectedIngredientsProvider.notifier)
                                  .removeIngredient(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Formular zum manuellen Hinzufügen weiterer Zutaten
              const Text(
                'Zutat manuell hinzufügen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Zutat',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Menge',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add_circle),
                    tooltip: 'Zutat hinzufügen',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Button für Rezeptvorschläge (nur anzeigen, wenn Zutaten erkannt wurden)
              if (ingredients.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _getRecipeSuggestions,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Rezeptvorschläge anzeigen'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCamera,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Kühlschrank fotografieren',
      ),
    );
  }

  Widget _buildImageSection(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kühlschrankbilder',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  'Klicke auf den Kamera-Button, um ein Foto zu machen',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageData = images[index];

                return Stack(
                  children: [
                    Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(imageData)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // Bild entfernen
                          final currentImages = [...images];
                          currentImages.removeAt(index);
                          ref
                              .read(fridgeScanStateProvider.notifier)
                              .setFridgeImages(currentImages);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  void _showEditIngredientDialog(
    BuildContext context,
    int index,
    Ingredient ingredient,
  ) {
    final nameController = TextEditingController(text: ingredient.name);

    // Teile die Messung in Menge und Einheit auf (z.B. "200 g" -> "200" und "g")
    final measureParts = ingredient.measure.split(' ');
    String amount = '';
    String unit = '';

    if (measureParts.isNotEmpty) {
      // Versuche den ersten Teil als Zahl zu interpretieren
      if (double.tryParse(measureParts[0]) != null) {
        amount = measureParts[0];
        if (measureParts.length > 1) {
          unit = measureParts.sublist(1).join(' ');
        }
      } else {
        // Wenn der erste Teil keine Zahl ist, behandle alles als Einheit
        unit = ingredient.measure;
      }
    }

    final amountController = TextEditingController(text: amount);
    final unitController = TextEditingController(text: unit);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Zutat bearbeiten'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Menge',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Einheit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () {
                  // Kombiniere Menge und Einheit zu einer Maßangabe
                  String measure = '';
                  if (amountController.text.isNotEmpty) {
                    measure = amountController.text;
                    if (unitController.text.isNotEmpty) {
                      measure += ' ' + unitController.text;
                    }
                  } else if (unitController.text.isNotEmpty) {
                    measure = unitController.text;
                  } else {
                    measure = 'nach Geschmack';
                  }

                  // Aktualisiere die Zutat
                  ref
                      .read(detectedIngredientsProvider.notifier)
                      .updateIngredient(
                        index,
                        Ingredient(
                          name:
                              nameController.text.isEmpty
                                  ? ingredient.name
                                  : nameController.text,
                          measure: measure,
                        ),
                      );

                  Navigator.of(context).pop();
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
    );
  }
}
