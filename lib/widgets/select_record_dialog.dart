import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/services/history_service.dart';

import '../models/record_item.dart';
import '../models/select_dialog_config.dart';
import '../services/RecordService.dart';
import 'search/search_bar_widget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  final stt.SpeechToText speech = stt.SpeechToText();

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    filters.addAll(widget.initialFilters);

    loadHistory();

    loadData();

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final position = scrollController.position;

      if (position.pixels >= position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  Future<void> loadHistory() async {
    final result = await HistoryService.get(widget.config.historyKey);

    if (!mounted) return;

    setState(() {
      history = result;
    });
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      loadingMore = false;
      page = 1;
      hasMore = true;
      records.clear();
    });

    try {
      final result = await widget.service.list(
        page: 1,
        sort: sort,
        filters: Map<String, String>.from(filters),
      );

      if (!mounted) return;

      setState(() {
        records = result.data;
        page = result.currentPage;
        hasMore = result.hasNextPage;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint('loadData error: $e');
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;

    setState(() {
      loadingMore = true;
    });

    try {
      final result = await widget.service.list(
        page: page + 1,
        sort: sort,
        filters: filters,
      );

      if (!mounted) return;

      setState(() {
        records.addAll(result.data);

        page = result.currentPage;

        hasMore = result.hasNextPage;

        loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingMore = false;
      });

      debugPrint('Load more error: $e');
    }
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

  void search(String value) {
    debounce?.cancel();

    final query = value.trim();

    debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (query.isEmpty) {
        filters.remove('search');
      } else {
        filters['search'] = query;
      }

      loadData();
    });
  }

  Future<void> showSortDialog() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('جدیدترین'),
              onTap: () => Navigator.pop(context, '-id'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('قدیمی‌ترین'),
              onTap: () => Navigator.pop(context, 'id'),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('عنوان (الف تا ی)'),
              onTap: () => Navigator.pop(context, 'title'),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('عنوان (ی تا الف)'),
              onTap: () => Navigator.pop(context, '-title'),
            ),
          ],
        ),
      ),
    );
    if (value != null && value != sort) {
      setState(() => sort = value);
      await loadData();
    }
  }

  Future<void> showFilterDialog() async {
    final serviceFilters = widget.service.filters;
    if (serviceFilters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برای این انتخاب‌گر فیلتر دیگری تعریف نشده است.')),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'فیلترهای انتخاب',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...serviceFilters.map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: filter.builder(
                            context,
                            filters,
                            () => setSheetState(() {}),
                            filter.field,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                filters.removeWhere((key, _) =>
                                    key != 'search' &&
                                    !key.startsWith('__label__'));
                                setSheetState(() {});
                              },
                              child: const Text('حذف فیلترها'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                loadData();
                              },
                              child: const Text('اعمال'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    speech.stop();
    super.dispose();
  }

  Future<void> _createRecord() async {
    final callback = widget.config.onCreate;
    if (callback == null) return;

    final created = await callback(context);
    if (created == null || !mounted) return;

    setState(() {
      records.removeWhere((item) => item.id == created.id);
      records.insert(0, created);
      selectedIds
        ..clear()
        ..add(created.id);
    });
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.config.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.config.onCreate != null &&
                      (widget.config.createPermission == null ||
                       context.read<UserController>().can(widget.config.createPermission!)))
                    IconButton(
                      tooltip: 'ایجاد جدید',
                      onPressed: _createRecord,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                ],
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

                // onVoice: toggleVoiceSearch,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: Text(
                      filters.entries.where((e) =>
                          e.value.isNotEmpty &&
                          e.key != 'search' &&
                          !e.key.startsWith('__label__')).isEmpty
                          ? "فیلتر"
                          : "فیلتر فعال",
                    ),
                    onPressed: showFilterDialog,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.sort),
                    label: const Text("مرتب سازی"),
                    onPressed: showSortDialog,
                  ),
                ],
              ),
            ),

            const Divider(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off, size: 48),
                                const SizedBox(height: 10),
                                const Text('موردی پیدا نشد.'),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: loadData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('تلاش مجدد'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                      controller: scrollController,
                      itemCount: records.length + (loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == records.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final item = records[index];

                        final selected = selectedIds.contains(item.id);

                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.description ?? ''),
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

  Future<void> toggleVoiceSearch() async {
    if (isListening) {
      await stopVoiceSearch();
    } else {
      await startVoiceSearch();
    }
  }

  Future<void> startVoiceSearch() async {
    final available = await speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          setState(() {
            isListening = false;
          });

          final text = searchController.text.trim();

          if (text.isNotEmpty) {
            filters['search'] = text;
            loadData();
          }
        } else {
          setState(() {
            isListening = status == 'listening';
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          isListening = false;
        });

        debugPrint('Speech error: ${error.errorMsg}');
      },
    );

    if (!available) return;

    setState(() {
      isListening = true;
    });

    await speech.listen(
      localeId: 'fa_IR',
      partialResults: true,
      listenMode: stt.ListenMode.search,
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          searchController.text = result.recognizedWords;

          searchController.selection = TextSelection.collapsed(
            offset: searchController.text.length,
          );
        });
      },
    );
  }

  Future<void> stopVoiceSearch() async {
    await speech.stop();

    if (!mounted) return;

    setState(() {
      isListening = false;
    });
  }
}
