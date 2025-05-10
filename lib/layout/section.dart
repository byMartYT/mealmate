import 'package:flutter/material.dart';
import 'package:mealmate_new/main.dart';

class Section extends StatelessWidget {
  Section({super.key, required this.title, required this.children})
    : assert(children.isNotEmpty, 'children must not be empty');

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kSpacing,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ...children,
      ],
    );
  }
}
