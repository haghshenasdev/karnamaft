
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/mobile_report.dart';
import '../services/calendar_service.dart';
import '../utils/date_helper.dart';
import 'task_show_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final service = const CalendarService();

  late Jalali current;
  CalendarData? data;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    current = Jalali.now();
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
      final result = await service.month(current.year, current.month);

      if (!mounted) return;

      setState(() {
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void moveMonth(int delta) {
    if (delta > 0) {
      if (current.month == 12) {
        current = Jalali(current.year + 1, 1, 1);
      } else {
        current = Jalali(current.year, current.month + 1, 1);
      }
    } else {
      if (current.month == 1) {
        current = Jalali(current.year - 1, 12, 1);
      } else {
        current = Jalali(current.year, current.month - 1, 1);
      }
    }

    load();
  }

  @override
  Widget build(BuildContext context) {
    final calendar = data;

    final byDay = <int, List<CalendarEvent>>{};

    final firstDayOffset =
        (current.toDateTime().weekday + 1) % 7;

    if (calendar != null) {
      for (final event in calendar.events) {
        if (event.date == null) continue;

        final jalali = Jalali.fromDateTime(event.date!);

        byDay.putIfAbsent(jalali.day, () => []).add(event);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقویم فعالیت‌ها'),
        actions: [
          IconButton(
            tooltip: 'ماه قبل',
            onPressed: loading ? null : () => moveMonth(-1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'ماه بعد',
            onPressed: loading ? null : () => moveMonth(1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, retry: load)
              : calendar == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${DateHelper.monthName(current.month)} ${current.year}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              for (final name in const [
                                'ش',
                                'ی',
                                'د',
                                'س',
                                'چ',
                                'پ',
                                'ج',
                              ])
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: .82,
                            ),
                            itemCount: calendar.days + firstDayOffset,
                            itemBuilder: (context, index) {
                              if (index < firstDayOffset) {
                                return const SizedBox.shrink();
                              }

                              final day = index - firstDayOffset + 1;
                              final events = byDay[day] ?? [];

                              return Card(
                                elevation: 0,
                                child: InkWell(
                                  onTap: events.isEmpty
                                      ? null
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            showDragHandle: true,
                                            builder: (_) => _DaySheet(
                                              day: day,
                                              events: events,
                                            ),
                                          );
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$day',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: events.isEmpty
                                                ? null
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                          ),
                                        ),
                                        if (events.isNotEmpty)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                for (final event
                                                    in events.take(3))
                                                  Container(
                                                    width: double.infinity,
                                                    margin:
                                                        const EdgeInsets.only(
                                                      top: 3,
                                                    ),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 3,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      event.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  final int day;
  final List<CalendarEvent> events;

  const _DaySheet({
    required this.day,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'فعالیت‌های روز $day',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          for (final event in events)
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  event.completed ? Icons.check : Icons.schedule,
                ),
              ),
              title: Text(event.title),
              subtitle: Text(
                '${event.progress ?? 0}%'
                '${event.city == null ? '' : ' • ${event.city}'}'
                '${event.date == null ? '' : ' • ${DateHelper.toTime(event.date)}'}',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskShowPage(
                      id: event.id,
                      title: event.title,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback retry;

  const _ErrorState({
    required this.message,
    required this.retry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
