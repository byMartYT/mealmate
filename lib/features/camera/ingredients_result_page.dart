import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmate_new/features/camera/ingredients_detection_provider.dart';
import 'package:mealmate_new/models/detected_ingredient.dart';

class IngredientsResultPage extends ConsumerWidget {
  const IngredientsResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(ingredientsDetectionProvider);

    // Zeige Ladebildschirm während der Verarbeitung
    if (detectionState.isProcessing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extracting Ingredients')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing image...'),
              SizedBox(height: 8),
              Text(
                'The AI is searching for ingredients',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Zeige Fehlerbildschirm, falls ein Fehler aufgetreten ist
    if (detectionState.status == DetectionStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  detectionState.errorMessage ?? 'Unknown Error occured',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Zeige die Zutatenliste
    return Scaffold(
      appBar: AppBar(
        title: const Text('Found Ingredients'),
        actions: [
          // Wähle alle/keine aus
          IconButton(
            onPressed: () => _handleNextPressed(context, ref),
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Choose Recipe',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIngredientDialog(context, ref),
        tooltip: 'Add ingredient',
        child: const Icon(Icons.add),
      ),
      body:
          detectionState.ingredients.isEmpty
              ? const Center(child: Text('No Ingredients found'))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${detectionState.ingredients.length} Ingredients found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: detectionState.ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = detectionState.ingredients[index];
                        return _buildIngredientTile(
                          context,
                          ref,
                          ingredient,
                          index,
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  // Baut ein Listenitem für eine Zutat
  Widget _buildIngredientTile(
    BuildContext context,
    WidgetRef ref,
    DetectedIngredient ingredient,
    int index,
  ) {
    return Dismissible(
      key: Key('ingredient_${index}_${ingredient.name}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(ingredientsDetectionProvider.notifier).removeIngredient(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ingredient.name} removed'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        title: Text(ingredient.name),
        subtitle:
            (ingredient.amount != null || ingredient.unit != null)
                ? Text(
                  [
                    if (ingredient.amount != null) ingredient.amount,
                    if (ingredient.unit != null) ingredient.unit,
                  ].where((e) => e != null).join(' '),
                )
                : null,
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed:
              () => _showAddIngredientDialog(
                context,
                ref,
                ingredient: ingredient,
                index: index,
              ),
        ),
      ),
    );
  }

  // Verarbeitet den Klick auf den Forward-Button
  void _handleNextPressed(BuildContext context, WidgetRef ref) async {
    final ingredients = ref.read(ingredientsDetectionProvider).ingredients;

    // Überprüfen, ob Zutaten vorhanden sind
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Rezeptvorschläge vom Backend abrufen
      final recommendations =
          await ref
              .read(ingredientsDetectionProvider.notifier)
              .getRecipeRecommendations();

      print('Recommendations received: $recommendations');

      // Rezeptvorschläge anzeigen
      if (context.mounted) {
        print('Showing recipe recommendations modal');
        _showRecipeRecommendations(context, recommendations);
      } else {
        print('Context not mounted when trying to show recommendations');
      }
    } catch (e) {
      // Dialog schließen bei Fehler
      if (context.mounted) Navigator.of(context).pop();

      // Fehlermeldung anzeigen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error in _handleNextPressed: $e');
    }
  }

  // Zeigt die Rezeptvorschläge in einem Modal an
  void _showRecipeRecommendations(BuildContext context, List<String> recipes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recipe Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Based on your ingredients, you could make:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(recipes[index]),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Hier könnte man zur Rezeptdetailseite navigieren
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${recipes[index]}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Zeigt einen Dialog zum Hinzufügen einer neuen Zutat oder Bearbeiten einer vorhandenen
  void _showAddIngredientDialog(
    BuildContext context,
    WidgetRef ref, {
    DetectedIngredient? ingredient,
    int? index,
  }) {
    final nameController = TextEditingController(text: ingredient?.name);
    final amountController = TextEditingController(text: ingredient?.amount);
    final unitController = TextEditingController(text: ingredient?.unit);

    final isEditing = ingredient != null && index != null;
    final dialogTitle = isEditing ? 'Edit ingredient' : 'Add new ingredient';
    final actionButtonText = isEditing ? 'Update' : 'Add';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ingredient name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'g, ml, piece, tsp, tbsp, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a name for the ingredient',
                            ),
                          ),
                        );
                        return;
                      }

                      // Neue Zutat erstellen
                      final newIngredient = DetectedIngredient(
                        name: nameController.text.trim(),
                        amount:
                            amountController.text.trim().isEmpty
                                ? null
                                : amountController.text.trim(),
                        unit:
                            unitController.text.trim().isEmpty
                                ? null
                                : unitController.text.trim(),
                      );

                      if (isEditing) {
                        // Zutat aktualisieren
                        ref
                            .read(ingredientsDetectionProvider.notifier)
                            .updateIngredient(index, newIngredient);

                        // Bestätigungsnachricht für Aktualisierung
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newIngredient.name} updated'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Zum Provider hinzufügen (neue Zutat)
                        ref
                            .read(ingredientsDetectionProvider.notifier)
                            .addIngredient(newIngredient);

                        // Bestätigungsnachricht für Hinzufügen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newIngredient.name} added'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      // Dialog schließen
                      Navigator.pop(context);
                    },
                    child: Text(actionButtonText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
