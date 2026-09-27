
import 'package:flutter/material.dart';

import '../models/project_children.dart';
import '../pages/letter_show_page.dart';
import '../pages/minute_show_page.dart';
import '../pages/task_show_page.dart';
import '../services/project_children_service.dart';
import '../utils/date_helper.dart';

class ProjectChildrenSection extends StatefulWidget {
  final int projectId;

  const ProjectChildrenSection({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectChildrenSection> createState() =>
      _ProjectChildrenSectionState();
}

class _ProjectChildrenSectionState extends State<ProjectChildrenSection> {
  final service = const ProjectChildrenService();

  int tab = 0;
  bool loading = true;
  String? error;

  List<ProjectChildLetter> letters = [];
  List<ProjectChildTask> tasks = [];
  List<ProjectChildMinute> minutes = [];
  List<ProjectChildApprove> approves = [];

  int lp = 1, ll = 1;
  int tp = 1, tl = 1;
  int mp = 1, ml = 1;
  int ap = 1, al = 1;

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
      if (tab == 0) {
        final result = await service.letters(widget.projectId);
        letters = result.data;
        lp = result.currentPage;
        ll = result.lastPage;
      } else if (tab == 1) {
        final result = await service.tasks(widget.projectId);
        tasks = result.data;
        tp = result.currentPage;
        tl = result.lastPage;
      } else if (tab == 2) {
        final result = await service.minutes(widget.projectId);
        minutes = result.data;
        mp = result.currentPage;
        ml = result.lastPage;
      } else {
        final result = await service.approves(widget.projectId);
        approves = result.data;
        ap = result.currentPage;
        al = result.lastPage;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  bool get hasMore {
    if (tab == 0) return lp < ll;
    if (tab == 1) return tp < tl;
    if (tab == 2) return mp < ml;
    return ap < al;
  }

  Future<void> loadMore() async {
    try {
      if (tab == 0 && lp < ll) {
        final result = await service.letters(
          widget.projectId,
          page: lp + 1,
        );

        if (!mounted) return;

        setState(() {
          letters.addAll(result.data);
          lp = result.currentPage;
        });
      } else if (tab == 1 && tp < tl) {
        final result = await service.tasks(
          widget.projectId,
          page: tp + 1,
        );

        if (!mounted) return;

        setState(() {
          tasks.addAll(result.data);
          tp = result.currentPage;
        });
      } else if (tab == 2 && mp < ml) {
        final result = await service.minutes(
          widget.projectId,
          page: mp + 1,
        );

        if (!mounted) return;

        setState(() {
          minutes.addAll(result.data);
          mp = result.currentPage;
        });
      } else if (tab == 3 && ap < al) {
        final result = await service.approves(
          widget.projectId,
          page: ap + 1,
        );

        if (!mounted) return;

        setState(() {
          approves.addAll(result.data);
          ap = result.currentPage;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
    }
  }

  void selectTab(int value) {
    if (value == tab) return;

    setState(() {
      tab = value;
      error = null;
    });

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'زیرمجموعه‌های دستورکار',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabChip(
                    value: 0,
                    label: 'نامه‌ها',
                    icon: Icons.mail_outline,
                  ),
                  _tabChip(
                    value: 1,
                    label: 'فعالیت‌ها',
                    icon: Icons.task_alt,
                  ),
                  _tabChip(
                    value: 2,
                    label: 'صورتجلسه‌ها',
                    icon: Icons.description_outlined,
                  ),
                  _tabChip(
                    value: 3,
                    label: 'مصوبه‌ها',
                    icon: Icons.gavel_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              )
            else ...[
              ..._buildItems(context),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('نمایش بیشتر'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabChip({
    required int value,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        label: Text(label),
        avatar: Icon(icon, size: 18),
        selected: tab == value,
        onSelected: (_) => selectTab(value),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    if (tab == 0) {
      return letters.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.mail_outline),
          ),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'شماره ${item.id} • ${DateHelper.toDate(item.createdAt)}',
          ),
          trailing: Icon(
            item.files.isEmpty
                ? Icons.chevron_left
                : Icons.attach_file,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LetterShowPage(
                  id: item.id,
                  title: item.title,
                ),
              ),
            );
          },
        );
      }).toList();
    }

    if (tab == 1) {
      return tasks.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Icon(
              item.completed ? Icons.check : Icons.task_alt,
            ),
          ),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.progress ?? 0}%'
            '${item.endedAt == null ? '' : ' • پایان ${DateHelper.toDateTime(item.endedAt)}'}'
            '${item.minuteTitle == null ? '' : ' • ${item.minuteTitle}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_left),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskShowPage(
                  id: item.id,
                  title: item.title,
                ),
              ),
            );
          },
        );
      }).toList();
    }

    if (tab == 2) {
      return minutes.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.description_outlined),
          ),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(DateHelper.toDate(item.date)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MinuteShowPage(
                  id: item.id,
                  title: item.title,
                ),
              ),
            );
          },
        );
      }).toList();
    }

    return approves.map((item) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          child: Icon(Icons.gavel_outlined),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.description ?? item.status ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }
}
