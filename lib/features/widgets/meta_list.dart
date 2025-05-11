import 'package:flutter/material.dart';

class Meta {
  final String text;
  final IconData icon;

  const Meta({required this.text, required this.icon});
}

class MetaList extends StatelessWidget {
  const MetaList(this.list, {super.key});

  final List<Meta> list;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: list.map((item) => MetaItem(item)).toList(),
    );
  }
}

class MetaItem extends StatelessWidget {
  const MetaItem(this.meta, {super.key});

  final Meta meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: [
        Icon(meta.icon, color: Color(0xFF666666), size: 20),
        Text(meta.text, style: TextStyle(color: Color(0xFF666666))),
      ],
    );
  }
}
