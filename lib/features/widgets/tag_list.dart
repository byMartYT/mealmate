import 'package:flutter/material.dart';

class TagList extends StatelessWidget {
  const TagList(this.tags, {super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 8,
      children: [
        for (var tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF0f0f0),
              borderRadius: BorderRadius.circular(200),
            ),
            child: Text(
              tag,
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
