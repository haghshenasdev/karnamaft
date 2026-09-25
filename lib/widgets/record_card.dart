import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/widgets/record_action_bar.dart';
import 'package:karnamaft/widgets/search/highlight_text.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class RecordCard extends StatelessWidget {
  final RecordItem record;
  final VoidCallback? onTap, onOpen, onFile, onRefer, onMore, onDelete;
  final String keyword;
  const RecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onOpen,
    this.onFile,
    this.onRefer,
    this.onMore,
    this.onDelete,
    this.keyword = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), cs = theme.colorScheme;
    final statusColor = record.status?.color(context);
    return Card(
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_iconForRecord(), color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HighlightText(
                          text: record.title,
                          keyword: keyword,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (record.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            record.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (statusColor != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        record.status!.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (record.from != null || record.to != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (record.from != null)
                      _metaChip(
                        context,
                        Icons.arrow_back_rounded,
                        'از ${record.from!}',
                      ),
                    if (record.to != null)
                      _metaChip(
                        context,
                        Icons.arrow_forward_rounded,
                        'به ${record.to!}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (record.number != null)
                    _metaChip(context, Icons.tag_outlined, record.number!),
                  if (record.date != null)
                    _metaChip(
                      context,
                      Icons.event_outlined,
                      jalaliToString(record.date),
                    ),
                  if (record.tag != null)
                    _metaChip(context, Icons.sell_outlined, record.tag!),
                  if (record.hasAttachment)
                    _metaChip(context, Icons.attach_file_rounded, 'پیوست'),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              RecordActionBar(
                onOpen: onOpen,
                onFile: onFile,
                onRefer: onRefer,
                onMore: onMore,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForRecord() {
    if (record.hasAttachment) return Icons.description_rounded;
    if (record.status != null) return Icons.assignment_outlined;
    return Icons.article_outlined;
  }

  Widget _metaChip(BuildContext context, IconData icon, String text) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  String jalaliToString(DateTime? date) {
    if (date == null) return '';
    final j = Jalali.fromDateTime(date);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }
}
