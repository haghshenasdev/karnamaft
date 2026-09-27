import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/mobile_report.dart';
import '../services/report_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final service = const ReportService();
  int tab = 0;
  int? year;
  bool loading = true;
  String? error;
  MobileReport? report;
  final resources = ['letters', 'minutes', 'tasks', 'projects'];
  final titles = ['نامه‌ها', 'صورتجلسه‌ها', 'فعالیت‌ها', 'دستورکارها'];

  @override
  void initState() {
    super.initState();
    year = Jalali.now().year;
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await service.report(resources[tab], year: year);
      if (!mounted) return;
      setState(() => report = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < titles.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(titles[i]),
                        selected: tab == i,
                        onSelected: (_) {
                          setState(() => tab = i);
                          load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'سال شمسی:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: year,
                  items: [
                    for (
                      int y = Jalali.now().year;
                      y >= Jalali.now().year - 5;
                      y--
                    )
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) {
                    setState(() => year = v);
                    load();
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: loading ? null : load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? _Error(error!, load)
                : r == null
                ? const SizedBox()
                : _ReportBody(report: r),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final MobileReport report;
  const _ReportBody({required this.report});
  @override
  Widget build(BuildContext context) {
    final max = report.monthly.fold<int>(
      1,
      (m, e) => e.count > m ? e.count : m,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Stat('کل', report.total, Icons.analytics_outlined),
            if (report.completed != null)
              _Stat('انجام‌شده', report.completed!, Icons.task_alt),
            _Stat(
              'ماه فعال',
              report.monthly.where((e) => e.count > 0).length,
              Icons.calendar_month,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          title: 'روند ماهانه',
          child: Column(
            children: [
              for (final m in report.monthly)
                _Bar(
                  label: m.name,
                  value: m.count,
                  max: max,
                  suffix: '${m.count}',
                ),
            ],
          ),
        ),
        if (report.status.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            title: 'توزیع وضعیت',
            child: Column(
              children: [
                for (final s in report.status)
                  _Bar(
                    label: s.label,
                    value: s.count,
                    max: report.total == 0 ? 1 : report.total,
                    suffix: '${s.count}',
                  ),
              ],
            ),
          ),
        ],
        if (report.groups.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            title: 'دسته‌بندی فعالیت‌ها',
            child: Column(
              children: [
                for (final g in report.groups)
                  _Bar(
                    label: g.name,
                    value: g.count,
                    max: report.groups
                        .map((x) => x.count)
                        .fold(1, (a, b) => a > b ? a : b),
                    suffix: '${g.count}',
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  const _Stat(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext c) => SizedBox(
    width: MediaQuery.sizeOf(c).width > 600 ? 190 : 160,
    child: Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    '$value',
                    style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
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
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});
  @override
  Widget build(BuildContext c) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              c,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String suffix;

  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;

    if (max > 0) {
      progress = value / max;
    }

    // اطمینان از اینکه مقدار همیشه بین 0 و 1 باشد
    progress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 34, child: Text(suffix, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String text;
  final VoidCallback retry;
  const _Error(this.text, this.retry);
  @override
  Widget build(BuildContext c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
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
