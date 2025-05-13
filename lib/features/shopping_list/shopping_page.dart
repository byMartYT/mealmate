import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Einkaufsliste'),
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
                  // Ist bereits implementiert durch GroupedListView
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear_checked',
                    child: Text('Erledigte entfernen'),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Text('Alle entfernen'),
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
                      color: Theme.of(context).primaryColor,
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
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            // Button zum Löschen aller Items eines Rezepts
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.onPrimary,
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

class ShoppingListItemTile extends ConsumerWidget {
  final ShoppingListItem item;

  const ShoppingListItemTile(this.item, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(shoppingListProvider.notifier).removeItem(item.id);
      },
      child: Card(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: CheckboxListTile(
          value: item.isChecked,
          onChanged: (_) {
            ref.read(shoppingListProvider.notifier).toggleItemCheck(item.id);
          },
          title: Text(
            item.ingredient.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            item.ingredient.measure,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color:
                  item.isChecked ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          secondary: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.restaurant,
              color:
                  item.isChecked ? Colors.grey : Theme.of(context).primaryColor,
            ),
          ),
          tileColor: item.isChecked ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }
}
