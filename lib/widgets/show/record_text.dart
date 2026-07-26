import 'package:flutter/material.dart';

class RecordText extends StatelessWidget {
  final String? text;

  const RecordText({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final content = (text ?? "").trim();

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //--------------------------------------------------
            // Header
            //--------------------------------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                  child: Icon(Icons.subject, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 16),

                Text(
                  "متن",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Text
            //--------------------------------------------------
            SelectableText(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
