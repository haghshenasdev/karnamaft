import 'package:flutter/material.dart';

class RecordField extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Widget? trailing;

  const RecordField({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
          ],

          SizedBox(
            width: 95,
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const Text(" : "),

          Expanded(
            child: SelectableText(
              value.isEmpty ? "-" : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ]
        ],
      ),
    );
  }
}