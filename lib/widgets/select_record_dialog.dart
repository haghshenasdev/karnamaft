import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karnamaft/services/history_service.dart';

import '../models/record_item.dart';
import '../models/select_dialog_config.dart';
import '../services/RecordService.dart';
import 'search/search_bar_widget.dart';

class SelectRecordDialog extends StatefulWidget {
  final RecordService service;

  final SelectDialogConfig config;
  final Map<String, String> initialFilters;

  const SelectRecordDialog({
    super.key,
    required this.service,
    required this.config,
    this.initialFilters = const {},
  });

  @override
  State<SelectRecordDialog> createState() => _SelectRecordDialogState();
}

class _SelectRecordDialogState extends State<SelectRecordDialog> {
  final TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  List<RecordItem> records = [];

  List<String> history = [];

  final Map<String, String> filters = {};

  String sort = "-id";

  bool loading = true;

  bool loadingMore = false;

  int page = 1;

  bool hasMore = true;

  Timer? debounce;

  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    filters.addAll(widget.initialFilters);

    loadHistory();

    loadData();

    scrollController.addListener(() {
      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  Future<void> loadHistory() async {
    history = await HistoryService.get(widget.config.historyKey);

    setState(() {});
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

    page = result.currentPage;

    hasMore = result.hasNextPage;

    setState(() {
      loading = false;
    });
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;

    loadingMore = true;

    final result = await widget.service.list(
      page: page + 1,
      sort: sort,
      filters: filters,
    );

    records.addAll(result.data);

    page = result.currentPage;

    hasMore = result.hasNextPage;

    loadingMore = false;

    setState(() {});
  }

  void search(String value) {
    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        filters.remove("search");
      } else {
        filters["search"] = value.trim();
      }

      loadData();
    });
  }

  void toggle(RecordItem item) {
    setState(() {
      if (widget.config.multiSelect) {
        if (selectedIds.contains(item.id)) {
          selectedIds.remove(item.id);
        } else {
          selectedIds.add(item.id);
        }
      } else {
        selectedIds = {item.id};
      }
    });
  }

  Future<void> confirm() async {
    await HistoryService.add(widget.config.historyKey, selectedIds.join(","));

    if (!mounted) return;

    Navigator.pop(
      context,

      widget.config.multiSelect
          ? records.where((e) => selectedIds.contains(e.id)).toList()
          : records.firstWhere((e) => e.id == selectedIds.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),

      child: SizedBox(
        width: 600,

        height: 650,

        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),

              child: Text(
                widget.config.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: SearchBarWidget(
                controller: searchController,

                hint: "جستجو",

                onChanged: search,

                onClear: () {
                  searchController.clear();
                  filters.remove("search");
                  loadData();
                },

                onVoice: () {},
              ),
            ),

            if (history.isNotEmpty)
              SizedBox(
                height: 45,

                child: ListView(
                  scrollDirection: Axis.horizontal,

                  children: history.map((e) {
                    return Padding(
                      padding: const EdgeInsets.all(4),

                      child: ActionChip(
                        label: Text(e),
                        onPressed: () {
                          searchController.text = e;
                          filters["search"] = e;
                          loadData();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.filter_alt),

                  label: const Text("فیلتر"),

                  onPressed: () {
                    // همان showFilterDialog صفحه RecordsPage
                  },
                ),

                TextButton.icon(
                  icon: const Icon(Icons.sort),

                  label: const Text("مرتب سازی"),

                  onPressed: () {},
                ),
              ],
            ),

            const Divider(),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,

                      itemCount: records.length + (loadingMore ? 1 : 0),

                      itemBuilder: (context, index) {
                        if (index == records.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final item = records[index];

                        final selected = selectedIds.contains(item.id);

                        return ListTile(
                          title: Text(item.title),

                          subtitle: Text(item.description!),

                          trailing: widget.config.multiSelect
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => toggle(item),
                                )
                              : Radio<int>(
                                  value: item.id,
                                  groupValue: selectedIds.firstOrNull,
                                  onChanged: (_) => toggle(item),
                                ),

                          onTap: () => toggle(item),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),

              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),

                      label: const Text("انصراف"),

                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),

                      label: const Text("انتخاب"),

                      onPressed: selectedIds.isEmpty ? null : confirm,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
