import 'package:flutter/material.dart';

import 'package:karnamaft/models/cartable_model.dart';
import 'package:karnamaft/models/task_model.dart';
import 'package:karnamaft/pages/letter_show_page.dart';
import 'package:karnamaft/pages/task_show_page.dart';
import 'package:karnamaft/services/cartable_service.dart';
import 'package:karnamaft/services/task_service.dart';

class CartablePage extends StatefulWidget {
  const CartablePage({super.key});

  @override
  State<CartablePage> createState() => _CartablePageState();
}

class _CartablePageState extends State<CartablePage> {
  final cartableService = const CartableService();
  final taskService = const TaskService();

  final search = TextEditingController();
  final scroll = ScrollController();

  List<CartableModel> letters = [];
  List<TaskModel> tasks = [];

  bool loading = true;
  bool loadingMore = false;

  bool? showOnlyUnread;

  String dueFilter = 'all';

  int letterPage = 1;
  int letterLastPage = 1;
  int taskPage = 1;
  int taskLastPage = 1;

  String? error;

  @override
  void initState() {
    super.initState();

    load();

    scroll.addListener(() {
      if (!scroll.hasClients) return;

      if (scroll.position.pixels >
          scroll.position.maxScrollExtent - 500) {
        loadMore();
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
        letters = [];
        tasks = [];
        letterPage = 1;
        taskPage = 1;
      });
    }

    try {
      final letterFuture = cartableService.list(
        search: search.text.trim(),
        checked: showOnlyUnread == null ? null : !showOnlyUnread!,
      );

      Future<dynamic> taskFuture() async {
        try {
          return await taskService.myTasks(
            search: search.text.trim(),
            due: dueFilter,
          );
        } catch (e) {
          // نداشتن مجوز فعالیت نباید کارپوشه نامه‌ها را از کار بیندازد.
          return e;
        }
      }

      final results = await Future.wait([
        letterFuture,
        taskFuture(),
      ]);

      if (!mounted) return;

      final letterResult = results[0];
      final taskResult = results[1];

      setState(() {
        letters = (letterResult as dynamic).data;
        letterPage = letterResult.currentPage;
        letterLastPage = letterResult.lastPage;

        if (taskResult is! Exception) {
          tasks = taskResult.data as List<TaskModel>;
          taskPage = taskResult.currentPage as int;
          taskLastPage = taskResult.lastPage as int;
        }
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

  Future<void> loadMore() async {
    if (loadingMore) return;

    final canLoadLetters = letterPage < letterLastPage;
    final canLoadTasks = taskPage < taskLastPage;

    if (!canLoadLetters && !canLoadTasks) return;

    setState(() => loadingMore = true);

    try {
      if (canLoadLetters) {
        final r = await cartableService.list(
          page: letterPage + 1,
          search: search.text.trim(),
          checked: showOnlyUnread == null ? null : !showOnlyUnread!,
        );

        if (mounted) {
          setState(() {
            letters.addAll(r.data);
            letterPage = r.currentPage;
            letterLastPage = r.lastPage;
          });
        }
      }

      if (canLoadTasks) {
        try {
          final r = await taskService.myTasks(
            page: taskPage + 1,
            search: search.text.trim(),
            due: dueFilter,
          );

          if (mounted) {
            setState(() {
              tasks.addAll(r.data);
              taskPage = r.currentPage;
              taskLastPage = r.lastPage;
            });
          }
        } catch (e) {
          debugPrint('MY TASKS LOAD MORE: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => loadingMore = false);
      }
    }
  }

  Future<void> _setChecked(CartableModel item, bool value, int index) async {
    try {
      final updated = await cartableService.setChecked(item.id, value);

      if (!mounted) return;

      setState(() {
        letters[index] = CartableModel(
          id: item.id,
          letterId: item.letterId,
          checked: updated.checked,
          createdAt: item.createdAt,
          updatedAt: updated.updatedAt,
          letter: item.letter,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('کارپوشه'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: search,
              hintText: 'جستجو در نامه‌ها و فعالیت‌های من',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (search.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      search.clear();
                      setState(() {});
                      load();
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => load(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('همه نامه‌ها'),
                    selected: showOnlyUnread == null,
                    onSelected: (_) {
                      setState(() => showOnlyUnread = null);
                      load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('خوانده نشده'),
                    selected: showOnlyUnread == true,
                    onSelected: (_) {
                      setState(() => showOnlyUnread = true);
                      load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('بررسی شده'),
                    selected: showOnlyUnread == false,
                    onSelected: (_) {
                      setState(() => showOnlyUnread = false);
                      load();
                    },
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: Text(
                      'فعالیت‌های من:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _dueChip('all', 'همه', Icons.list_alt_rounded),
                  _dueChip('overdue', 'گذشته', Icons.warning_amber_rounded),
                  _dueChip('today', 'امروز', Icons.today_rounded),
                  _dueChip('upcoming', 'آینده', Icons.event_available_rounded),
                  _dueChip(
                    'without_deadline',
                    'بدون مهلت',
                    Icons.event_busy_rounded,
                  ),
                  _dueChip('completed', 'انجام‌شده', Icons.task_alt_rounded),
                ],
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _ErrorView(error: error!, onRetry: load)
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          children: [
                            _SectionHeader(
                              title: 'نامه‌های ارجاع‌شده',
                              count: letters.length,
                              icon: Icons.forward_to_inbox_outlined,
                            ),
                            if (letters.isEmpty)
                              const _EmptySection(
                                text: 'نامه ارجاع‌شده‌ای در این فیلتر وجود ندارد.',
                              )
                            else
                              ...letters.asMap().entries.map(
                                (entry) => _letterCard(
                                  entry.value,
                                  entry.key,
                                  cs,
                                ),
                              ),

                            const SizedBox(height: 12),

                            _SectionHeader(
                              title: 'فعالیت‌های مسئولیت من',
                              count: tasks.length,
                              icon: Icons.assignment_turned_in_outlined,
                            ),
                            if (tasks.isEmpty)
                              const _EmptySection(
                                text: 'فعالیتی با این فیلتر برای شما پیدا نشد.',
                              )
                            else
                              ...tasks.map(_taskCard),

                            if (loadingMore)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _dueChip(String value, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        avatar: Icon(icon, size: 17),
        label: Text(label),
        selected: dueFilter == value,
        onSelected: (_) {
          if (dueFilter == value) return;
          setState(() => dueFilter = value);
          load();
        },
      ),
    );
  }

  Widget _letterCard(
    CartableModel item,
    int index,
    ColorScheme cs,
  ) {
    final letter = item.letter;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: letter == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LetterShowPage(
                      id: letter.id,
                      title: 'نامه ${letter.id}',
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.checked
                        ? cs.surfaceContainerHighest
                        : cs.primaryContainer,
                    child: Icon(
                      item.checked
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      color: item.checked
                          ? cs.onSurfaceVariant
                          : cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      letter?.subject ?? 'نامه شماره ${item.letterId}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch.adaptive(
                    value: item.checked,
                    onChanged: (value) => _setChecked(item, value, index),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  InputChip(
                    label: Text('نامه ${item.letterId}'),
                    onPressed: null,
                  ),
                  if (letter?.organ != null)
                    InputChip(
                      avatar: const Icon(
                        Icons.business_outlined,
                        size: 16,
                      ),
                      label: Text(letter!.organ!),
                      onPressed: null,
                    ),
                  if (letter?.daftar != null)
                    InputChip(
                      avatar: const Icon(
                        Icons.account_balance_outlined,
                        size: 16,
                      ),
                      label: Text(letter!.daftar!),
                      onPressed: null,
                    ),
                  if (letter != null)
                    ...letter.projects.map(
                      (e) => InputChip(
                        label: Text(e),
                        onPressed: null,
                      ),
                    ),
                ],
              ),
              if (letter?.customers.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('صاحب: ${letter!.customers.join('، ')}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard(TaskModel task) {
    final color = task.isCompleted
        ? Colors.green
        : task.isOverdue
            ? Colors.red
            : task.isDueToday
                ? Colors.orange
                : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskShowPage(
                id: task.id,
                title: task.name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(
                      task.isCompleted
                          ? Icons.task_alt_rounded
                          : Icons.assignment_outlined,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${task.progress ?? 0}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if ((task.description ?? '').isNotEmpty)
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(
                      task.isOverdue
                          ? Icons.warning_amber_rounded
                          : task.isDueToday
                              ? Icons.today_rounded
                              : Icons.schedule_rounded,
                      size: 17,
                    ),
                    label: Text(task.deadlineText),
                  ),
                  if (task.city != null)
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 17),
                      label: Text(task.city!.name),
                    ),
                  if (task.organ != null)
                    Chip(
                      avatar: const Icon(Icons.business_outlined, size: 17),
                      label: Text(task.organ!.name),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          text,
          textAlign: TextAlign.center,
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
            const Icon(Icons.cloud_off_rounded, size: 60),
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
