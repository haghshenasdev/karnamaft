import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/widgets/record_card.dart';

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
  Timer? _searchDebounce;
  String sort = "-id";
  final Map<String, String> filters = {};

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    loadData();

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 250) {
        loadMore();
      }
    });
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      records.clear();
    });

    final result = await widget.service.list(
      page: 1,
      sort: sort,
      filters: filters,
    );

    records = result.data;

    totalCount = result.total;
    currentPage = result.currentPage;
    hasMore = result.hasNextPage;

    setState(() {
      loading = false;
    });
  }

  Future<void> loadMore() async {
    if (loadingMore) return;

    if (!hasMore) return;

    loadingMore = true;

    setState(() {});

    final result = await widget.service.list(
      page: currentPage + 1,
      sort: sort,
      filters: filters,
    );

    records.addAll(result.data);

    currentPage = result.currentPage;

    hasMore = result.hasNextPage;

    loadingMore = false;

    setState(() {});
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

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        filters.remove("search");
      } else {
        filters["search"] = value.trim();
      }

      currentPage = 1;
      hasMore = true;

      loadData();
    });
  }

  void clearSearch() {
    searchController.clear();

    filters.remove("search");

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
      backgroundColor: const Color(0xfff5f6fa),

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

                onVoice: () {},
              ),
            ),

            //--------------------------------------------------
            // Filter Bar
            //--------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

            const SizedBox(height: 12),

            const Divider(height: 1),

            //--------------------------------------------------
            // Records
            //--------------------------------------------------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
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
