import 'package:flutter/material.dart';

class Meta {
  final String text;
  final IconData icon;

  const Meta({required this.text, required this.icon});
}

class MetaList extends StatelessWidget {
  const MetaList(this.list, {super.key, this.color = const Color(0xFF666666)});

  final List<Meta> list;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: list.map((item) => MetaItem(item, color)).toList(),
    );
  }
}

class MetaItem extends StatelessWidget {
  const MetaItem(this.meta, this.color, {super.key});

  final Meta meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: [
        Icon(meta.icon, color: color, size: 20),
        Text(meta.text, style: TextStyle(color: color)),
      ],
    );
  }
}
