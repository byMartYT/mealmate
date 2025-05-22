import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/shopping_list/shopping_list_item.dart';
import 'package:mealmate_new/features/shopping_list/shopping_list_provider.dart';
import 'package:mealmate_new/models/shopping_list_item.dart';
import 'package:grouped_list/grouped_list.dart';

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hole die Einkaufsliste vom Provider
    final shoppingList = ref.watch(shoppingListProvider);

    // Sortieren: Erst nach Rezept, dann nach Status (nicht abgehakt zuerst)
    final sortedItems = [...shoppingList]..sort((a, b) {
      // Primär nach Rezept sortieren
      final recipeCompare = a.recipeName.compareTo(b.recipeName);
      if (recipeCompare != 0) return recipeCompare;

      // Sekundär nach Status sortieren (nicht abgehakt zuerst)
      return a.isChecked == b.isChecked ? 0 : (a.isChecked ? 1 : -1);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          // Popup-Menü für Aktionen
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'clear_checked':
                  await ref
                      .read(shoppingListProvider.notifier)
                      .removeCheckedItems();
                  break;
                case 'clear_all':
                  await ref
                      .read(shoppingListProvider.notifier)
                      .clearShoppingList();
                  break;
                case 'sort_recipe':
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear_checked',
                    child: Text('Clear checked'),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Text('Clear all'),
                  ),
                ],
          ),
        ],
      ),
      body:
          shoppingList.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Deine Einkaufsliste ist leer',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Füge Zutaten aus Rezepten hinzu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : GroupedListView<ShoppingListItem, String>(
                elements: sortedItems,
                groupBy: (item) => item.recipeName,
                groupSeparatorBuilder:
                    (recipeName) => Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rezeptbild
                            _buildRecipeImage(sortedItems, recipeName),
                            // Rezeptname
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  recipeName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            // Button zum Löschen aller Items eines Rezepts
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                              onPressed: () {
                                // Suche die recipeId anhand des ersten Items mit diesem Namen
                                final recipeId =
                                    sortedItems
                                        .firstWhere(
                                          (item) =>
                                              item.recipeName == recipeName,
                                        )
                                        .recipeId;
                                ref
                                    .read(shoppingListProvider.notifier)
                                    .removeRecipeItems(recipeId);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                itemBuilder: (context, item) => ShoppingListItemTile(item),
                order: GroupedListOrder.ASC,
                padding: const EdgeInsets.all(8),
              ),
    );
  }

  // Bild des Rezepts für die Gruppe anzeigen
  Widget _buildRecipeImage(List<ShoppingListItem> items, String recipeName) {
    // Finde das erste Item mit diesem Rezeptnamen
    final item = items.firstWhere((item) => item.recipeName == recipeName);

    if (item.recipeImage == '_') null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.network(
          item.recipeImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 20),
            );
          },
        ),
      ),
    );
  }
}
