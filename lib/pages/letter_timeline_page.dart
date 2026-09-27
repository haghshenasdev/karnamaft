import 'package:flutter/material.dart';

import 'package:karnamaft/models/letter_timeline.dart';
import 'package:karnamaft/services/letter_timeline_service.dart';
import 'package:karnamaft/utils/date_helper.dart';

class LetterTimelinePage extends StatefulWidget {
  final int letterId;
  final String title;

  const LetterTimelinePage({
    super.key,
    required this.letterId,
    required this.title,
  });

  @override
  State<LetterTimelinePage> createState() => _LetterTimelinePageState();
}

class _LetterTimelinePageState extends State<LetterTimelinePage> {
  final service = const LetterTimelineService();
  bool loading = true;
  String? error;
  List<LetterTimelineItem> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final result = await service.list(widget.letterId);
      if (!mounted) return;
      setState(() {
        items = result.reversed.toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  IconData _icon(LetterTimelineItem item) {
    switch (item.type) {
      case 'referral':
        return Icons.forward_to_inbox_rounded;
      case 'answer':
        return Icons.chat_bubble_outline_rounded;
      case 'referral_activity':
        return Icons.sync_alt_rounded;
      case 'letter':
        return Icons.mark_email_read_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  Color _color(BuildContext context, LetterTimelineItem item) {
    final scheme = Theme.of(context).colorScheme;
    switch (item.color) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'info':
        return scheme.primary;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'بارگذاری مجدد',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorView(error: error!, onRetry: load)
              : items.isEmpty
                  ? const Center(child: Text('برای این نامه سابقه‌ای ثبت نشده است.'))
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final color = _color(context, item);

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 42,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: .12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _icon(item),
                                          size: 19,
                                          color: color,
                                        ),
                                      ),
                                      if (index != items.length - 1)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            margin: const EdgeInsets.symmetric(vertical: 5),
                                            color: color.withValues(alpha: .18),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              if (item.createdAt != null)
                                                Text(
                                                  DateHelper.longDateTime(item.createdAt),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                            ],
                                          ),
                                          if (item.description.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(item.description),
                                          ],
                                          if ((item.user ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 7),
                                            Text(
                                              'کاربر: ${item.user}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                          if (item.changes.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            const Divider(),
                                            ...item.changes.map(
                                              (change) => Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  '${change.label}: '
                                                  '${change.oldValue ?? "—"} ← '
                                                  '${change.newValue ?? "—"}',
                                                  style: const TextStyle(fontSize: 12.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64),
            const SizedBox(height: 14),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
