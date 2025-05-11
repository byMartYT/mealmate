import 'package:flutter/material.dart';

class InstructionsList extends StatelessWidget {
  const InstructionsList(this.instructions, {super.key});

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        // Jedes Element einzeln mit vertikalem Abstand
        ...instructions.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InstructionItem(
              text: entry.value,
              index: entry.key + 1, // Sicherer als indexOf
            ),
          ),
        ),
      ],
    );
  }
}

class InstructionItem extends StatelessWidget {
  const InstructionItem({super.key, required this.text, required this.index});

  final String text;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nummer in einem Container
        Container(
          width: 80,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Text(
            'Step $index',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),

        // Text darunter mit vollem Platz
        Text(
          text,
          style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}
