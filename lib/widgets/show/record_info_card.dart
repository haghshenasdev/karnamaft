import 'package:flutter/material.dart';

class RecordInfoCard extends StatelessWidget {
  final List<Widget> children;

  const RecordInfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = children.where((e) => e != null).toList();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                "اطلاعات",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const Divider(height: 1),

            for (int i = 0; i < items.length; i++) ...[
              items[i],

              if (i != items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }
}
