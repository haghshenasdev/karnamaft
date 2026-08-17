import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karnamaft/models/search_item.dart';
import 'package:karnamaft/models/search_page_mapper.dart';
import 'package:karnamaft/repository/search_repository.dart';
import 'package:karnamaft/services/history_service.dart';
import 'package:karnamaft/widgets/search/empty_widget.dart';
import 'package:karnamaft/widgets/search/filter_bar.dart';
import 'package:karnamaft/widgets/search/group_header.dart';
import 'package:karnamaft/widgets/search/result_card.dart';
import 'package:karnamaft/widgets/search/search_bar_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  //--------------------------------------------------
  // Controller
  //--------------------------------------------------

  final TextEditingController controller = TextEditingController();
  bool loading = false;
  Timer? _searchTimer;

  //--------------------------------------------------
  // Filter
  //--------------------------------------------------

  SearchType? selectedType;

  //------------------------------------------------
  //
  // Recent Search
  //
  //------------------------------------------------

  List<String> recentSearches = [];

  static const String searchHistoryKey = "search_history";

  //------------------------------------------------
  //
  // Suggestions
  //
  //------------------------------------------------

  final List<String> suggestions = [
    "نامه",
    "صورت جلسه",
    "یادداشت",
    "فعالیت",
    "بودجه",
    "دانشگاه",
    "هیئت علمی",
  ];

  //--------------------------------------------------
  // Result
  //--------------------------------------------------

  List<SearchItem> results = [];

  //--------------------------------------------------
  // Group
  //--------------------------------------------------

  Map<SearchType, List<SearchItem>> groups = {};

  //--------------------------------------------------
  // Expand State
  //--------------------------------------------------

  final Map<SearchType, bool> expanded = {};
  final Map<SearchType, int> pages = {
    SearchType.letter: 1,
    SearchType.meeting: 1,
    SearchType.activity: 1,
    SearchType.agenda: 1,
    SearchType.workspace: 1,
  };

  final Map<SearchType, bool> hasMore = {};

  final Map<SearchType, bool> loadingMore = {};

  //--------------------------------------------------
  // Init
  //--------------------------------------------------
  Future<void> _loadHistory() async {
    final data = await HistoryService.get(searchHistoryKey);

    if (!mounted) return;

    setState(() {
      recentSearches = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();

    controller.addListener(() {
      _searchTimer?.cancel();

      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        _search();
      });
    });

    _search();
  }

  @override
  void dispose() {
    controller.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  //--------------------------------------------------
  // Search
  //--------------------------------------------------

  Future<void> _search() async {
    final keyword = controller.text.trim();

    if (keyword.isEmpty) {
      setState(() {
        results = [];

        groups = {};
      });

      return;
    }

    pages.updateAll((key, value) => 1);

    setState(() {
      loading = true;
    });

    try {
      final data = await SearchRepository.search(
        keyword: keyword,
        pages: pages,
        hasMore: hasMore,
        filter: selectedType,
      );

      results = data;

      groups = SearchRepository.groupByType(results);
      setState(() {});

      for (final type in groups.keys) {
        expanded.putIfAbsent(type, () => true);
      }
    } catch (e) {
      debugPrint("SEARCH ERROR: $e");

      results = [];

      groups = {};
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _saveSearchHistory() async {
    final keyword = controller.text.trim();

    if (keyword.isEmpty) return;

    await HistoryService.add(searchHistoryKey, keyword);

    await _loadHistory();
  }

  Future<void> loadMore(SearchType type) async {
    if (loadingMore[type] == true) return;

    if (hasMore[type] == false) return;

    setState(() {
      loadingMore[type] = true;
    });

    final currentPage = pages[type] ?? 1;

    final nextPage = currentPage + 1;

    try {
      final data = await SearchRepository.search(
        keyword: controller.text.trim(),

        pages: {...pages, type: nextPage},

        hasMore: hasMore,

        filter: type,
      );

      final newItems = data.where((e) => e.type == type).toList();

      setState(() {
        pages[type] = nextPage;

        groups[type] = [...(groups[type] ?? []), ...newItems];

        results = groups.values.expand((items) => items).toList();
      });
    } catch (e) {
      debugPrint("LOAD MORE ERROR $type : $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingMore[type] = false;
        });
      }
    }
  }

  void _searchByText(String text) {
    controller.text = text;

    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    _search();
  }

  //--------------------------------------------------
  // Filter
  //--------------------------------------------------

  void _changeFilter(SearchType? type) {
    selectedType = type;

    _search();
  }

  //--------------------------------------------------
  // Expand
  //--------------------------------------------------

  void _toggleGroup(SearchType type) {
    expanded[type] = !(expanded[type] ?? true);

    setState(() {});
  }

  void _openResult(SearchItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("انتخاب شد: ${item.title}"),

        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  //--------------------------------------------------
  // Build
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: SafeArea(
        child: Column(
          children: [
            //--------------------------------------------------
            // Search
            //--------------------------------------------------
            Hero(
              tag: "global_search",

              child: Material(
                color: Colors.transparent,

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),

                  child: SearchBarWidget(
                    controller: controller,
                    hint: "جستجو در همه اطلاعات...",
                    onChanged: (_) => _search(),
                    onClear: _search,
                    backBtn: true,
                    autofocus: true,
                  ),
                ),
              ),
            ),

            //--------------------------------------------------
            // Filter
            //--------------------------------------------------
            SearchFilterBar(
              selected: selectedType,
              onChanged: (type) {
                _changeFilter(type);
              },
            ),

            const SizedBox(height: 12),

            //--------------------------------------------------
            // Result
            //--------------------------------------------------
            Expanded(
              child: controller.text.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 30),

                      children: [
                        //----------------------------------------
                        // Recent
                        //----------------------------------------
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),

                          child: Row(
                            children: [
                              const Text(
                                "آخرین جستجوها",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Spacer(),

                              TextButton(
                                onPressed: () async {
                                  await HistoryService.clear(searchHistoryKey);

                                  await _loadHistory();
                                },
                                child: const Text("پاک کردن"),
                              ),
                            ],
                          ),
                        ),

                        ...recentSearches.map((text) {
                          return ListTile(
                            leading: const Icon(Icons.history),

                            title: Text(text),

                            trailing: IconButton(
                              icon: const Icon(Icons.north_west),

                              onPressed: () {
                                _searchByText(text);
                              },
                            ),

                            onTap: () {
                              _searchByText(text);
                            },
                          );
                        }),

                        const SizedBox(height: 22),

                        //----------------------------------------
                        // Suggestion
                        //----------------------------------------
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),

                          child: Text(
                            "پیشنهادها",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),

                          child: Wrap(
                            spacing: 10,

                            runSpacing: 10,

                            children: suggestions.map((text) {
                              return ActionChip(
                                avatar: const Icon(Icons.search, size: 18),

                                label: Text(text),

                                onPressed: () {
                                  _searchByText(text);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  : loading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                  ? EmptySearchWidget(keyword: controller.text)
                  : Column(
                      children: [
                        //------------------------------------------------
                        // Result Header
                        //------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: Row(
                            children: [
                              //--------------------------------
                              // Count
                              //--------------------------------
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "${results.length} نتیجه",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  selectedType == null
                                      ? "نمایش همه نتایج"
                                      : selectedType!.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),

                              //--------------------------------
                              // Sort
                              //--------------------------------
                              FilledButton.tonalIcon(
                                onPressed: () {},

                                icon: const Icon(Icons.swap_vert),

                                label: const Text("مرتب سازی"),
                              ),
                            ],
                          ),
                        ),

                        //---------------------------------------
                        // Divider
                        //---------------------------------------
                        Divider(
                          height: 1,
                          thickness: .7,
                          color: Colors.grey.shade300,
                        ),

                        //---------------------------------------
                        // Result List
                        //---------------------------------------
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),

                            padding: const EdgeInsets.only(top: 12, bottom: 24),

                            children: groups.entries.map((entry) {
                              final type = entry.key;

                              final items = entry.value;

                              final isExpanded = expanded[type] ?? true;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //------------------------------------------------
                                  // Group Header
                                  //------------------------------------------------
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: SearchGroupHeader(
                                      type: type,
                                      count: items.length,
                                      expanded: isExpanded,
                                      onTap: () {
                                        _toggleGroup(type);
                                      },
                                    ),
                                  ),

                                  //------------------------------------------------
                                  // Group Items
                                  //------------------------------------------------
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),

                                    switchInCurve: Curves.easeOut,

                                    switchOutCurve: Curves.easeIn,

                                    child: !isExpanded
                                        ? const SizedBox.shrink()
                                        : Column(
                                            key: ValueKey(type),

                                            children: List.generate(items.length, (
                                              index,
                                            ) {
                                              final item = items[index];

                                              return TweenAnimationBuilder<
                                                double
                                              >(
                                                tween: Tween(begin: 0, end: 1),

                                                duration: Duration(
                                                  milliseconds:
                                                      120 + (index * 40),
                                                ),

                                                curve: Curves.easeOut,

                                                builder:
                                                    (context, value, child) {
                                                      return Opacity(
                                                        opacity: value,

                                                        child:
                                                            Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                (1 - value) *
                                                                    20,
                                                              ),

                                                              child: child,
                                                            ),
                                                      );
                                                    },

                                                child: SearchResultCard(
                                                  item: item,

                                                  keyword: controller.text,

                                                  onTap: () async {
                                                    await _saveSearchHistory();
                                                    Navigator.push(
                                                      context,

                                                      MaterialPageRoute(
                                                        builder: (_) {
                                                          return SearchPageMapper.open(
                                                            context,
                                                            item,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }),
                                          ),
                                  ),
                                  if (hasMore[type] ?? false)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 8,
                                      ),

                                      child: FilledButton.tonalIcon(
                                        onPressed: loadingMore[type] == true
                                            ? null
                                            : () async {
                                                await loadMore(type);
                                              },

                                        icon: loadingMore[type] == true
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.expand_more),

                                        label: Text(
                                          loadingMore[type] == true
                                              ? "در حال دریافت..."
                                              : "نمایش بیشتر",
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                    ),
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      height: 18,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  //------------------------------------------------
                                  //
                                  // End Group
                                  //
                                  //------------------------------------------------
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: const SizedBox(height: 6),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        //------------------------------------------------
                        //
                        // Bottom Space
                        //
                        //------------------------------------------------
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
