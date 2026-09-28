import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/mobile_report.dart';
import '../services/calendar_service.dart';
import '../utils/date_helper.dart';
import 'letter_show_page.dart';
import 'minute_show_page.dart';
import 'task_show_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarService service = const CalendarService();

  late Jalali current;
  CalendarData? data;

  bool loading = true;
  String? error;

  String selectedType = 'all';

  static const monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  @override
  void initState() {
    super.initState();
    current = Jalali.now();
    load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await service.month(
        current.year,
        current.month,
        type: selectedType,
      );

      if (!mounted) return;

      setState(() {
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        data = null;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void changeMonth(int delta) {
    final year = current.year;
    final month = current.month;

    if (delta > 0) {
      current = month == 12
          ? Jalali(year + 1, 1, 1)
          : Jalali(year, month + 1, 1);
    } else {
      current = month == 1
          ? Jalali(year - 1, 12, 1)
          : Jalali(year, month - 1, 1);
    }

    load();
  }

  void changeYear(int year) {
    final month = current.month;
    final maxDay = Jalali(year, month, 1).monthLength;
    final day = current.day > maxDay ? maxDay : current.day;

    setState(() {
      current = Jalali(year, month, day);
    });

    load();
  }

  void changeMonthDropdown(int month) {
    final maxDay = Jalali(current.year, month, 1).monthLength;
    final day = current.day > maxDay ? maxDay : current.day;

    setState(() {
      current = Jalali(current.year, month, day);
    });

    load();
  }

  Color eventColor(BuildContext context, CalendarEvent event) {
    final scheme = Theme.of(context).colorScheme;

    switch (event.type) {
      case 'letter':
        return Colors.green.shade600;
      case 'minute':
        return Colors.orange.shade700;
      case 'task':
      default:
        return scheme.primary;
    }
  }

  String typeTitle(String type) {
    switch (type) {
      case 'letter':
        return 'نامه';
      case 'minute':
        return 'صورتجلسه';
      case 'task':
        return 'فعالیت';
      default:
        return 'همه';
    }
  }

  IconData typeIcon(String type) {
    switch (type) {
      case 'letter':
        return Icons.mail_outline;
      case 'minute':
        return Icons.description_outlined;
      case 'task':
        return Icons.task_alt;
      default:
        return Icons.apps;
    }
  }

  void openEvent(CalendarEvent event) {
    Widget page;

    switch (event.type) {
      case 'letter':
        page = LetterShowPage(
          id: event.id,
          title: event.title,
        );
        break;

      case 'minute':
        page = MinuteShowPage(
          id: event.id,
          title: event.title,
        );
        break;

      case 'task':
      default:
        page = TaskShowPage(
          id: event.id,
          title: event.title,
        );
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> showDayEvents(
    int day,
    List<CalendarEvent> events,
  ) async {
    if (events.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .55,
            minChildSize: .35,
            maxChildSize: .9,
            builder: (_, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'رویدادهای روز $day',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  for (final event in events)
                    Card(
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              eventColor(context, event).withValues(alpha: .12),
                          foregroundColor: eventColor(context, event),
                          child: Icon(typeIcon(event.type)),
                        ),
                        title: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            event.typeTitle,
                            if (event.city != null && event.city!.isNotEmpty)
                              event.city!,
                            if (event.date != null)
                              DateHelper.toTime(event.date),
                          ].join(' • '),
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          openEvent(event);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendar = data;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    final firstDayOffset =
        (Jalali(current.year, current.month, 1).toDateTime().weekday + 1) % 7;

    final byDay = <int, List<CalendarEvent>>{};

    if (calendar != null) {
      for (final event in calendar.events) {
        if (event.date == null) continue;

        final jalali = Jalali.fromDateTime(event.date!);

        if (jalali.year != current.year || jalali.month != current.month) {
          continue;
        }

        byDay.putIfAbsent(jalali.day, () => <CalendarEvent>[]).add(event);
      }
    }

    final years = List<int>.generate(
      11,
      (index) => Jalali.now().year + 5 - index,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقویم'),
        actions: [
          IconButton(
            tooltip: 'ماه قبل',
            onPressed: loading ? null : () => changeMonth(-1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'ماه بعد',
            onPressed: loading ? null : () => changeMonth(1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 12,
              8,
              compact ? 8 : 12,
              4,
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: compact ? 135 : 170,
                      child: DropdownButtonFormField<int>(
                        value: current.year,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'سال',
                          isDense: true,
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        items: [
                          for (final y in years)
                            DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ),
                        ],
                        onChanged: loading || current.year == null
                            ? null
                            : (value) {
                                if (value != null) changeYear(value);
                              },
                      ),
                    ),
                    SizedBox(
                      width: compact ? 145 : 180,
                      child: DropdownButtonFormField<int>(
                        value: current.month,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ماه',
                          isDense: true,
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                        items: [
                          for (int m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(monthNames[m - 1]),
                            ),
                        ],
                        onChanged: loading
                            ? null
                            : (value) {
                                if (value != null) {
                                  changeMonthDropdown(value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in const [
                        ('all', 'همه'),
                        ('task', 'فعالیت‌ها'),
                        ('letter', 'نامه‌ها'),
                        ('minute', 'صورتجلسه‌ها'),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            avatar: Icon(
                              item.$1 == 'all'
                                  ? Icons.apps
                                  : item.$1 == 'task'
                                      ? Icons.task_alt
                                      : item.$1 == 'letter'
                                          ? Icons.mail_outline
                                          : Icons.description_outlined,
                              size: 17,
                            ),
                            label: Text(item.$2),
                            selected: selectedType ==
                                (item.$1 == 'task'
                                    ? 'tasks'
                                    : item.$1 == 'letter'
                                        ? 'letters'
                                        : item.$1 == 'minute'
                                            ? 'minutes'
                                            : 'all'),
                            onSelected: (_) {
                              final apiType = item.$1 == 'task'
                                  ? 'tasks'
                                  : item.$1 == 'letter'
                                      ? 'letters'
                                      : item.$1 == 'minute'
                                          ? 'minutes'
                                          : 'all';

                              if (apiType == selectedType) return;

                              setState(() {
                                selectedType = apiType;
                              });

                              load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Expanded(
              child: _ErrorState(
                message: error!,
                retry: load,
              ),
            )
          else if (calendar == null)
            const Expanded(
              child: Center(child: Text('اطلاعاتی برای نمایش وجود ندارد.')),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellHeight = compact ? 72.0 : 94.0;

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 4 : 8,
                          vertical: 6,
                        ),
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
                                    style: TextStyle(
                                      fontSize: compact ? 11 : 13,
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
                          padding: EdgeInsets.fromLTRB(
                            compact ? 4 : 8,
                            0,
                            compact ? 4 : 8,
                            12,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisExtent: cellHeight,
                            crossAxisSpacing: compact ? 2 : 5,
                            mainAxisSpacing: compact ? 2 : 5,
                          ),
                          itemCount: calendar.days + firstDayOffset,
                          itemBuilder: (context, index) {
                            if (index < firstDayOffset) {
                              return const SizedBox.shrink();
                            }

                            final day = index - firstDayOffset + 1;
                            final events = byDay[day] ?? const <CalendarEvent>[];

                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: events.isEmpty
                                    ? null
                                    : () => showDayEvents(day, events),
                                child: Padding(
                                  padding: EdgeInsets.all(compact ? 4 : 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          fontSize: compact ? 11 : 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (events.isNotEmpty)
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: Wrap(
                                              spacing: 3,
                                              runSpacing: 3,
                                              children: [
                                                for (final event
                                                    in events.take(8))
                                                  Container(
                                                    width: compact ? 7 : 9,
                                                    height: compact ? 7 : 9,
                                                    decoration: BoxDecoration(
                                                      color: eventColor(
                                                        context,
                                                        event,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
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
                  );
                },
              ),
            ),
          _Legend(compact: compact),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final bool compact;

  const _Legend({required this.compact});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Colors.blue, 'فعالیت'),
      (Colors.green, 'نامه'),
      (Colors.orange, 'صورتجلسه'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 16,
        2,
        compact ? 8 : 16,
        compact ? 6 : 10,
      ),
      child: Wrap(
        spacing: compact ? 10 : 18,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.$1,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.$2,
                  style: TextStyle(fontSize: compact ? 10 : 12),
                ),
              ],
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
            const Icon(Icons.cloud_off_rounded, size: 58),
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
