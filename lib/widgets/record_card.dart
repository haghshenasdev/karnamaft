import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/widgets/record_action_bar.dart';

class RecordCard extends StatelessWidget {
  final RecordItem record;

  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onFile;
  final VoidCallback? onRefer;
  final VoidCallback? onMore;

  const RecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onOpen,
    this.onFile,
    this.onRefer,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //--------------------------------------
              // Title
              //--------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: record.status.color(context).withOpacity(.12),

                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.status.title,
                      style: TextStyle(
                        color: record.status.color(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              //--------------------------------------
              // From / To
              //--------------------------------------
              if (record.from != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  title: "از",
                  value: record.from!,
                ),

              if (record.to != null)
                _InfoRow(
                  icon: Icons.arrow_forward,
                  title: "به",
                  value: record.to!,
                ),

              if (record.from != null || record.to != null)
                const SizedBox(height: 14),

              //--------------------------------------
              // Number / Date
              //--------------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.number != null) Chip(label: Text(record.number!)),

                  if (record.date != null) Chip(label: Text(record.date!)),

                  if (record.tag != null)
                    Chip(
                      avatar: const Icon(Icons.sell_outlined, size: 16),
                      label: Text(record.tag!),
                    ),

                  if (record.hasAttachment)
                    const Chip(
                      avatar: Icon(Icons.attach_file, size: 16),
                      label: Text("پیوست"),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              Divider(height: 1, color: theme.colorScheme.outlineVariant),

              const SizedBox(height: 8),

              //--------------------------------------
              // Actions
              //--------------------------------------
              RecordActionBar(
                onOpen: onOpen,
                onFile: onFile,
                onRefer: onRefer,
                onMore: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),

          const SizedBox(width: 8),

          Text(
            "$title : ",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          Expanded(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
