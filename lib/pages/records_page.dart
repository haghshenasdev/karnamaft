import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/widgets/record_card.dart';
import '../offline/offline_store.dart';
import '../utils/app_settings.dart';
import '../offline/offline_sync_service.dart';

import '../../widgets/search/search_bar_widget.dart';

class RecordsPage extends StatefulWidget {
  final String title;
  final RecordService service;
  final Widget Function(int id, String title) showPageBuilder;

  /// صفحه ایجاد رکورد
  final Widget Function()? createPageBuilder;
  final String? createSuccessMessage;

  const RecordsPage({
    super.key,
    required this.title,
    required this.service,
    required this.showPageBuilder,
    this.createPageBuilder,
    this.createSuccessMessage,
  });

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool loading = true;

  int totalCount = 0;

  List<RecordItem> records = [];

  bool loadingMore = false;

  int currentPage = 1;

  bool hasMore = true;

  String search = "";
  String? loadError;
  Timer? _searchDebounce;
  Timer? _offlineCacheRefreshTimer;
  String sort = "-id";
  final Map<String, String> filters = {};

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _offlineCacheRefreshTimer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    loadData();
    _offlineCacheRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshCachedRecordsDuringSync(),
    );

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 250) {
        loadMore();
      }
    });
  }

  Future<void> _refreshCachedRecordsDuringSync() async {
    if (!mounted || !OfflineSyncService.isSyncing) return;

    final enabled = await AppSettings.getOfflineEnabled();
    final resource = _offlineResourceName();
    if (!enabled || resource == null) return;

    try {
      final cached = await OfflineStore.instance.readCachedRecords(
        resource: resource,
        userId: 'current-user',
      );
      if (!mounted || cached.isEmpty) return;

      final localRecords = cached
          .map(_recordItemFromCache)
          .whereType<RecordItem>()
          .toList();

      if (localRecords.isEmpty) return;

      // Preserve search/filter behavior: only live-refresh the unfiltered list.
      if (search.trim().isNotEmpty || filters.values.any((v) => v.isNotEmpty)) {
        return;
      }

      final existingIds = records.map((r) => r.id).toSet();
      final newIds = localRecords.map((r) => r.id).toSet();
      if (existingIds.length == newIds.length &&
          existingIds.containsAll(newIds)) {
        return;
      }

      if (!mounted) return;
      setState(() {
        records = localRecords;
        totalCount = localRecords.length;
        currentPage = 1;
        hasMore = false;
        loading = false;
        loadError = 'همگام‌سازی در حال انجام است؛ اطلاعات ذخیره‌شده تا این لحظه نمایش داده می‌شود.';
      });
    } catch (_) {
      // A cache refresh failure must not interrupt the current screen.
    }
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
        records = [];
      });
    }

    // اگر حالت آفلاین فعال باشد، ابتدا نسخه محلی را فوراً نشان بده؛
    // سپس در صورت دسترسی، داده‌های سرور جایگزین نسخه محلی می‌شوند.
    final offlineEnabled = await AppSettings.getOfflineEnabled();
    final offlineResource = _offlineResourceName();
    if (offlineEnabled && offlineResource != null) {
      try {
        final cached = await OfflineStore.instance.readCachedRecords(
          resource: offlineResource,
          userId: 'current-user',
        );
        final localRecords = cached.map(_recordItemFromCache).whereType<RecordItem>().toList();
        if (localRecords.isNotEmpty && mounted) {
          setState(() {
            records = localRecords;
            totalCount = localRecords.length;
            currentPage = 1;
            hasMore = false;
            loading = false;
            loadError = 'حالت آفلاین فعال است؛ برای دریافت تغییرات جدید، از تنظیمات همگام‌سازی را اجرا کنید.';
          });
          return;
        }
      } catch (_) {
        // اگر کش خراب یا خالی باشد، بارگذاری عادی سرور ادامه پیدا می‌کند.
      }
    }

    try {
      final result = await widget.service.list(
        page: 1,
        sort: sort,
        search: search.trim().isEmpty ? null : search.trim(),
        filters: _apiFilters(),
      );

      if (!mounted) return;

      setState(() {
        records = result.data;
        totalCount = result.total;
        currentPage = result.currentPage;
        hasMore = result.hasNextPage;
        loading = false;
        loadError = null;
      });

      if (offlineEnabled && offlineResource != null) {
        await OfflineStore.instance.cacheRecords(
          resource: offlineResource,
          userId: 'current-user',
          records: result.data.map((r) => <String, dynamic>{
            'id': r.id,
            'title': r.title,
            'description': r.description,
            'from': r.from,
            'to': r.to,
            'number': r.number,
            'date': r.date?.toIso8601String(),
            'tag': r.tag,
            'has_attachment': r.hasAttachment,
          }).toList(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        final enabled = await AppSettings.getOfflineEnabled();
        final resource = _offlineResourceName();
        if (enabled && resource != null) {
          final cached = await OfflineStore.instance.readCachedRecords(
            resource: resource,
            userId: 'current-user',
          );
          if (cached.isNotEmpty) {
            final localRecords = cached.map(_recordItemFromCache).whereType<RecordItem>().toList();
            if (localRecords.isNotEmpty) {
              setState(() {
                records = localRecords;
                totalCount = localRecords.length;
                currentPage = 1;
                hasMore = false;
                loading = false;
                loadError = 'نمایش نسخه محلی؛ اتصال به سرور برقرار نیست.';
              });
              return;
            }
          }
        }
      } catch (_) {
        // Keep the original server error if local cache cannot be read.
      }
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  String? _offlineResourceName() {
    final name = widget.service.runtimeType.toString().toLowerCase();
    if (name.contains('letter')) return 'letters';
    if (name.contains('minute')) return 'minutes';
    if (name.contains('content')) return 'contents';
    if (name.contains('project')) return 'projects';
    if (name.contains('task')) return 'tasks';
    return null;
  }

  RecordItem? _recordItemFromCache(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id'] ?? json['uuid'] ?? ''}');
    if (id == null) return null;
    final date = DateTime.tryParse('${json['date'] ?? json['created_at'] ?? ''}');
    return RecordItem(
      id: id,
      title: '${json['title'] ?? json['subject'] ?? json['name'] ?? 'بدون عنوان'}',
      description: json['description']?.toString() ?? json['text']?.toString(),
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      number: json['number']?.toString(),
      date: date,
      tag: json['tag']?.toString(),
      hasAttachment: json['has_attachment'] == true || json['file_url'] != null,
    );
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;

    setState(() => loadingMore = true);

    try {
      final result = await widget.service.list(
        page: currentPage + 1,
        sort: sort,
        search: search.trim().isEmpty ? null : search.trim(),
        filters: _apiFilters(),
      );

      if (!mounted) return;

      setState(() {
        records.addAll(result.data);
        currentPage = result.currentPage;
        hasMore = result.hasNextPage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Map<String, String> _apiFilters() {
    final result = <String, String>{};

    filters.forEach((key, value) {
      if (key == 'search' || key.startsWith('__label__')) {
        return;
      }

      if (value.isNotEmpty) {
        result[key] = value;
      }
    });

    return result;
  }

  String _filterDisplayLabel(String field, String value) {
    final labels = <String, String>{
      'status': 'وضعیت',
      'completed': 'وضعیت انجام',
      'project_id': 'دستورکار',
      'city_id': 'شهر',
      'organ_id': 'دستگاه مربوطه',
      'Responsible_id': 'مسئول',
      'type_id': 'نوع نامه',
      'task_id': 'فعالیت',
      'created_at': 'تاریخ ثبت',
      'updated_at': 'تاریخ بروزرسانی',
      'date': 'تاریخ',
      'started_at': 'شروع',
      'ended_at': 'پایان',
      'completed_at': 'تکمیل',
    };

    final title = labels[field] ?? 'فیلتر';

    final values = <String, String>{
      '0': field == 'status' ? 'جدید' : 'انجام نشده',
      '1': field == 'status' ? 'اتمام' : 'انجام شده',
      '2': 'در حال پیگیری',
      '3': 'غیرقابل پیگیری',
    };

    final labelValue = filters['__label__$field'];

    if (labelValue != null && labelValue.isNotEmpty) {
      return '$title: $labelValue';
    }

    if (field == 'completed' && values.containsKey(value)) {
      return '$title: ${values[value]}';
    }

    if (field == 'status' && values.containsKey(value)) {
      return '$title: ${values[value]}';
    }

    if (field == 'created_at' ||
        field == 'updated_at' ||
        field == 'date' ||
        field == 'started_at' ||
        field == 'ended_at' ||
        field == 'completed_at') {
      return '$title: $value';
    }

    return '$title: انتخاب‌شده';
  }

  Future<void> changeSort(String value) async {
    if (sort == value) return;

    sort = value;
    currentPage = 1;
    hasMore = true;

    await loadData();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _offlineCacheRefreshTimer?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      search = value.trim();

      currentPage = 1;
      hasMore = true;

      loadData();
    });
  }

  void clearSearch() {
    searchController.clear();

    search = "";

    currentPage = 1;
    hasMore = true;

    loadData();
  }
  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      appBar: AppBar(
        title: Text(widget.title),

        centerTitle: false,

        elevation: 0,

        scrolledUnderElevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            //--------------------------------------------------
            // Search
            //--------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchBarWidget(
                controller: searchController,

                hint: "جستجو...",

                onChanged: onSearchChanged,

                onClear: clearSearch,

              ),
            ),

            //--------------------------------------------------
            // Filter Bar
            //--------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: showFilterDialog,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text("فیلتر"),
                  ),

                  const SizedBox(width: 8),

                  FilledButton.tonalIcon(
                    onPressed: showSortDialog,
                    icon: const Icon(Icons.sort),
                    label: const Text("مرتب سازی"),
                  ),

                  const Spacer(),

                  Text("$totalCount رکورد", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            if (filters.entries
                .where(
                  (e) =>
                      e.value.isNotEmpty &&
                      e.key != 'search' &&
                      !e.key.startsWith('__label__'),
                )
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.entries
                        .where(
                          (e) =>
                              e.value.isNotEmpty &&
                              e.key != 'search' &&
                              !e.key.startsWith('__label__'),
                        )
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InputChip(
                              label: Text(_filterDisplayLabel(e.key, e.value)),
                              onDeleted: () {
                                setState(() {
                                  filters.remove(e.key);
                                  filters.remove('__label__${e.key}');
                                });
                                loadData();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

            const SizedBox(height: 4),
            const Divider(height: 1),

            //--------------------------------------------------
            // Records
            //--------------------------------------------------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (loadError != null && records.isEmpty)
                      ? _RecordsErrorView(
                          message: loadError!,
                          onRetry: loadData,
                        )
                      : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 100),
                      itemCount: records.length + (loadingMore ? 1 : 0),

                      itemBuilder: (_, index) {
                        if (index == records.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final record = records[index];

                        return RecordCard(
                          record: record,

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => widget.showPageBuilder(
                                  record.id,
                                  "${widget.title} ${record.id}",
                                ),
                              ),
                            );
                          },

                          onOpen: () {},

                          onFile: () {},

                          onRefer: null,

                          onMore: () {},
                          onDelete: () async {
                            final confirmed = await showDeleteDialog(context);
                            if (!confirmed) return;

                            final messenger = ScaffoldMessenger.of(context);

                            // بستن پیام‌های قبلی
                            messenger.clearMaterialBanners();

                            // نمایش بنر در حال حذف
                            messenger.showMaterialBanner(
                              const MaterialBanner(
                                leading: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                content: Text("در حال حذف رکورد..."),
                                actions: [SizedBox.shrink()],
                              ),
                            );

                            final success = await widget.service.delete(
                              record.id,
                            );

                            // بستن بنر
                            messenger.clearMaterialBanners();

                            if (!context.mounted) return;

                            if (success) {
                              setState(() {
                                records.removeWhere((e) => e.id == record.id);
                                totalCount--;
                              });

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("رکورد با موفقیت حذف شد."),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("حذف رکورد انجام نشد."),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          keyword: filters["search"] ?? '',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: widget.createPageBuilder == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => widget.createPageBuilder!(),
                  ),
                );

                if (!mounted || result == null) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.createSuccessMessage ?? "رکورد با موفقیت ایجاد شد",
                    ),
                  ),
                );

                await loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text("جدید"),
            ),
    );
  }

  Future<void> showSortDialog() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text("جدیدترین"),
                onTap: () => Navigator.pop(context, "-id"),
              ),

              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("قدیمی‌ترین"),
                onTap: () => Navigator.pop(context, "id"),
              ),

              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("عنوان (الف تا ی)"),
                onTap: () => Navigator.pop(context, "title"),
              ),

              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("عنوان (ی تا الف)"),
                onTap: () => Navigator.pop(context, "-title"),
              ),
            ],
          ),
        );
      },
    );

    if (value != null) {
      await changeSort(value);
    }
  }

  Future<void> showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "فیلترها",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ...widget.service.filters.map((filter) {
                      return filter.builder(context, filters, () {
                        setSheetState(() {});
                      }, filter.field);
                    }),
                    const Divider(),

                    //--------------------------------------------------
                    // Buttons
                    //--------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              filters.clear();
                              loadData();
                              setSheetState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text("حذف فیلترها"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              loadData();

                              Navigator.pop(context);
                            },
                            child: const Text("اعمال"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> showDeleteDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('حذف'),
          content: const Text(
            'آیا از حذف این مورد مطمئن هستید؟\nاین عملیات قابل بازگشت نیست.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}


class _RecordsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RecordsErrorView({
    required this.message,
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
            const Icon(Icons.cloud_off_rounded, size: 58),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
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
