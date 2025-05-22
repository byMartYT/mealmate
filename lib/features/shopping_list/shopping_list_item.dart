import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmate_new/features/shopping_list/shopping_list_provider.dart';
import 'package:mealmate_new/models/shopping_list_item.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
            child: Icon(
              Icons.restaurant,
              color:
                  item.isChecked
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
