import 'package:flutter/material.dart';

import '../models/mobile_report.dart';
import '../services/report_service.dart';

class ProjectReportPage extends StatefulWidget {
  final int id;
  final String title;

  const ProjectReportPage({super.key, required this.id, required this.title});

  @override
  State<ProjectReportPage> createState() => _ProjectReportPageState();
}

class _ProjectReportPageState extends State<ProjectReportPage> {
  final ReportService service = const ReportService();

  ProjectReport? report;
  bool loading = true;
  String? error;

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
      final result = await service.projectReport(widget.id);

      if (!mounted) return;

      setState(() {
        report = result;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        report = null;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectReport? currentReport = report;

    return Scaffold(
      appBar: AppBar(title: Text('گزارش ${widget.title}')),
      body: _buildBody(currentReport),
    );
  }

  Widget _buildBody(ProjectReport? currentReport) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentReport == null) {
      return const Center(child: Text('اطلاعاتی برای نمایش وجود ندارد.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatistics(currentReport),
        const SizedBox(height: 16),
        _buildMonthlyReport(currentReport),
        const SizedBox(height: 16),
        _buildCitiesReport(currentReport),
      ],
    );
  }

  Widget _buildStatistics(ProjectReport report) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatCard(
          title: 'فعالیت‌ها',
          value: report.tasksTotal,
          icon: Icons.task_alt,
        ),
        _StatCard(
          title: 'انجام‌شده',
          value: report.tasksCompleted,
          icon: Icons.check_circle,
        ),
        _StatCard(
          title: 'باز',
          value: report.tasksOpen,
          icon: Icons.pending_actions,
        ),
        _StatCard(
          title: 'نامه‌ها',
          value: report.lettersTotal,
          icon: Icons.mail_outline,
        ),
        _StatCard(
          title: 'صورتجلسه‌ها',
          value: report.minutesTotal,
          icon: Icons.description_outlined,
        ),
        _StatCard(title: 'به‌موقع', value: report.onTime, icon: Icons.timer),
        _StatCard(
          title: 'با تأخیر',
          value: report.delayed,
          icon: Icons.warning_amber,
        ),
      ],
    );
  }

  Widget _buildMonthlyReport(ProjectReport report) {
    int maxValue = 1;

    for (final month in report.monthly) {
      if (month.count > maxValue) {
        maxValue = month.count;
      }
    }

    return _ReportBox(
      title: 'روند ماهانه فعالیت‌ها',
      child: report.monthly.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text('اطلاعات ماهانه‌ای وجود ندارد.'),
            )
          : Column(
              children: [
                for (final month in report.monthly)
                  _ProgressBar(
                    label: month.name,
                    value: month.count,
                    max: maxValue,
                    suffix: '${month.count}',
                  ),
              ],
            ),
    );
  }

  Widget _buildCitiesReport(ProjectReport report) {
    return _ReportBox(
      title: 'وضعیت شهرها',
      child: report.cities.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text('اطلاعات شهری وجود ندارد.'),
            )
          : Column(
              children: [
                for (final city in report.cities)
                  _ProgressBar(
                    label: city.name,
                    value: city.completed,
                    max: city.total > 0 ? city.total : 1,
                    suffix: '${city.completed}/${city.total}',
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width > 700 ? 170 : 145;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 2),
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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
}

class _ReportBox extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportBox({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String suffix;

  const _ProgressBar({
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

    progress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 11),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 45, child: Text(suffix, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
