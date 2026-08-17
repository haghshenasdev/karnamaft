import 'dart:async';

import 'package:flutter/material.dart';
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
    history = await HistoryService.get(widget.config.historyKey);

    setState(() {});
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

                onVoice: toggleVoiceSearch,
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
