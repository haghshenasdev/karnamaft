import 'dart:async';

import 'package:dio/dio.dart';
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
  // ============================================================
  // Controller
  // ============================================================

  final TextEditingController controller = TextEditingController();

  bool loading = false;

  Timer? _searchTimer;

  CancelToken? _searchCancelToken;

  int _searchGeneration = 0;

  // ============================================================
  // Filter
  // ============================================================

  SearchType? selectedType;

  // ============================================================
  // Recent Search
  // ============================================================

  List<String> recentSearches = [];

  static const String searchHistoryKey = 'search_history';

  // ============================================================
  // Result
  // ============================================================

  List<SearchItem> results = [];

  // ============================================================
  // Group
  // ============================================================

  Map<SearchType, List<SearchItem>> groups = {};

  // ============================================================
  // Expand State
  // ============================================================

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

  // ============================================================
  // Init
  // ============================================================

  Future<void> _loadHistory() async {
    try {
      final data = await HistoryService.get(searchHistoryKey);

      if (!mounted) return;

      setState(() {
        recentSearches = data;
      });
    } catch (e) {
      debugPrint('SEARCH HISTORY ERROR: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _loadHistory();

    // فقط این listener مسئول debounce جستجو است.
    controller.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    _searchTimer?.cancel();

    final keyword = controller.text.trim();

    if (keyword.isEmpty) {
      _search();
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _search();
    });

    // برای اینکه UI متن جدید را بلافاصله ببیند،
    // نیازی به setState نیست؛ TextField خودش rebuild می‌شود.
  }

  @override
  void dispose() {
    _searchTimer?.cancel();

    _searchCancelToken?.cancel('صفحه جستجو بسته شد');

    controller.removeListener(_onSearchTextChanged);
    controller.dispose();

    super.dispose();
  }

  // ============================================================
  // Search
  // ============================================================

  Future<void> _search() async {
    final keyword = controller.text.trim();

    final generation = ++_searchGeneration;

    // لغو درخواست قبلی
    _searchCancelToken?.cancel('جستجوی جدید');

    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    // ============================================================
    // Empty Search
    // ============================================================

    if (keyword.isEmpty) {
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        results = [];
        groups = {};
        loading = false;
      });

      return;
    }

    // ============================================================
    // Reset Pagination
    // ============================================================

    pages.updateAll((key, value) => 1);

    hasMore.clear();
    loadingMore.clear();

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await SearchRepository.search(
        keyword: keyword,
        pages: pages,
        hasMore: hasMore,
        filter: selectedType,
        cancelToken: cancelToken,
      );

      // ============================================================
      // جلوگیری از اعمال نتیجه قدیمی
      // ============================================================

      if (!mounted || generation != _searchGeneration) {
        return;
      }

      // اگر request لغو شده باشد، نتیجه آن را استفاده نکن.
      if (cancelToken.isCancelled) {
        return;
      }

      final grouped = SearchRepository.groupByType(data);

      setState(() {
        results = data;
        groups = grouped;
        loading = false;
      });

      for (final type in grouped.keys) {
        expanded.putIfAbsent(type, () => true);
      }
    } catch (e) {
      // ============================================================
      // Cancelled Request
      // ============================================================

      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }

      if (cancelToken.isCancelled) {
        return;
      }

      // نتیجه قدیمی نباید UI را تغییر دهد.
      if (!mounted || generation != _searchGeneration) {
        return;
      }

      debugPrint('SEARCH ERROR: $e');

      String message = 'خطا در انجام جستجو';

      // ============================================================
      // Dio Errors
      // ============================================================

      if (e is DioException) {
        final statusCode = e.response?.statusCode;

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = 'ارتباط با سرور بیش از حد طول کشید.';
            break;

          case DioExceptionType.connectionError:
            message = 'اتصال به اینترنت یا سرور برقرار نیست.';
            break;

          case DioExceptionType.badCertificate:
            message = 'گواهی امنیتی سرور معتبر نیست.';
            break;

          case DioExceptionType.cancel:
            return;

          case DioExceptionType.badResponse:
            if (statusCode == 401) {
              message = 'نشست کاربری شما منقضی شده است.';
            } else if (statusCode == 403) {
              message = 'شما اجازه دسترسی به این اطلاعات را ندارید.';
            } else if (statusCode == 404) {
              message = 'اطلاعات موردنظر پیدا نشد.';
            } else if (statusCode == 422) {
              message = 'اطلاعات جستجو معتبر نیست.';
            } else if (statusCode == 429) {
              message = 'تعداد درخواست‌ها زیاد است. کمی بعد دوباره تلاش کنید.';
            } else if (statusCode != null && statusCode >= 500) {
              message = 'سرور با مشکل مواجه شده است. لطفاً دوباره تلاش کنید.';
            } else {
              message = 'پاسخ نامعتبر از سرور دریافت شد.';
            }
            break;

          case DioExceptionType.unknown:
            message = 'ارتباط با سرور برقرار نشد.';
            break;
          case DioExceptionType.transformTimeout:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      }

      setState(() {
        results = [];
        groups = {};
        loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'تلاش مجدد',
              onPressed: () {
                _search();
              },
            ),
          ),
        );
    }
  }

  // ============================================================
  // Search History
  // ============================================================

  Future<void> _saveSearchHistory() async {
    final keyword = controller.text.trim();

    if (keyword.isEmpty) return;

    try {
      await HistoryService.add(searchHistoryKey, keyword);

      await _loadHistory();
    } catch (e) {
      debugPrint('SAVE SEARCH HISTORY ERROR: $e');
    }
  }

  // ============================================================
  // Load More
  // ============================================================

  Future<void> loadMore(SearchType type) async {
    if (loadingMore[type] == true) {
      return;
    }

    if (hasMore[type] == false) {
      return;
    }

    final keyword = controller.text.trim();

    if (keyword.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      loadingMore[type] = true;
    });

    final currentPage = pages[type] ?? 1;
    final nextPage = currentPage + 1;

    // درخواست مستقل برای load more
    final cancelToken = CancelToken();

    try {
      final data = await SearchRepository.search(
        keyword: keyword,
        pages: {...pages, type: nextPage},
        hasMore: hasMore,
        filter: type,
        cancelToken: cancelToken,
      );

      if (!mounted) {
        return;
      }

      final newItems = data.where((e) => e.type == type).toList();

      // جلوگیری از duplicate
      final existingIds = {for (final item in groups[type] ?? []) item.id};

      final uniqueItems = newItems
          .where((item) => !existingIds.contains(item.id))
          .toList();

      setState(() {
        pages[type] = nextPage;

        groups[type] = [...(groups[type] ?? []), ...uniqueItems];

        results = groups.values.expand((items) => items).toList();
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }

      if (!mounted) {
        return;
      }

      debugPrint('LOAD MORE ERROR $type : $e');

      String message = 'دریافت اطلاعات بیشتر انجام نشد.';

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          message = 'اتصال به اینترنت یا سرور برقرار نیست.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          message = 'ارتباط با سرور بیش از حد طول کشید.';
        } else if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 500) {
          message = 'سرور با مشکل مواجه شده است.';
        }
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    } finally {
      if (mounted) {
        setState(() {
          loadingMore[type] = false;
        });
      }
    }
  }

  // ============================================================
  // Search By History
  // ============================================================

  void _searchByText(String text) {
    controller.text = text;

    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    // listener خود controller جستجو را با debounce انجام می‌دهد.
  }

  // ============================================================
  // Filter
  // ============================================================

  void _changeFilter(SearchType? type) {
    if (selectedType == type) {
      return;
    }

    setState(() {
      selectedType = type;
    });

    _search();
  }

  // ============================================================
  // Expand
  // ============================================================

  void _toggleGroup(SearchType type) {
    if (!mounted) return;

    setState(() {
      expanded[type] = !(expanded[type] ?? true);
    });
  }

  // ============================================================
  // Open Result
  // ============================================================

  Future<void> _openResult(SearchItem item) async {
    await _saveSearchHistory();

    if (!mounted) return;

    try {
      final page = SearchPageMapper.open(context, item);

      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    } catch (e) {
      debugPrint('OPEN SEARCH RESULT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('باز کردن مورد انتخاب‌شده انجام نشد.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // Search
            // ======================================================
            Hero(
              tag: 'global_search',
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SearchBarWidget(
                    controller: controller,
                    hint: 'جستجو در همه اطلاعات...',

                    // مهم:
                    // اینجا دیگر _search() را مستقیم صدا نمی‌زنیم.
                    // controller listener خودش debounce را انجام می‌دهد.
                    onChanged: (_) {},

                    onClear: () {
                      controller.clear();
                    },

                    backBtn: true,
                    autofocus: true,
                  ),
                ),
              ),
            ),

            // ======================================================
            // Filter
            // ======================================================
            SearchFilterBar(selected: selectedType, onChanged: _changeFilter),

            const SizedBox(height: 12),

            // ======================================================
            // Result
            // ======================================================
            Expanded(
              child: controller.text.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        // ==========================================
                        // Recent Search Header
                        // ==========================================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                          child: Row(
                            children: [
                              const Text(
                                'آخرین جستجوها',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Spacer(),

                              TextButton(
                                onPressed: () async {
                                  try {
                                    await HistoryService.clear(
                                      searchHistoryKey,
                                    );

                                    await _loadHistory();
                                  } catch (e) {
                                    debugPrint(
                                      'CLEAR SEARCH HISTORY ERROR: $e',
                                    );
                                  }
                                },
                                child: const Text('پاک کردن'),
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Recent Search Items
                        // ==========================================
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
                      ],
                    )
                  : loading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                  ? EmptySearchWidget(keyword: controller.text)
                  : Column(
                      children: [
                        // ==================================
                        // Result Header
                        // ==================================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '${results.length} نتیجه',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  selectedType == null
                                      ? 'نمایش همه نتایج'
                                      : selectedType!.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),

                              FilledButton.tonalIcon(
                                onPressed: () {},
                                icon: const Icon(Icons.swap_vert),
                                label: const Text('مرتب سازی'),
                              ),
                            ],
                          ),
                        ),

                        // ==================================
                        // Divider
                        // ==================================
                        Divider(
                          height: 1,
                          thickness: .7,
                          color: Colors.grey.shade300,
                        ),

                        // ==================================
                        // Result List
                        // ==================================
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
                                  // ========================
                                  // Group Header
                                  // ========================
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

                                  // ========================
                                  // Group Items
                                  // ========================
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: !isExpanded
                                        ? const SizedBox.shrink()
                                        : Column(
                                            key: ValueKey(type),
                                            children: List.generate(
                                              items.length,
                                              (index) {
                                                final item = items[index];

                                                return SearchResultCard(
                                                  item: item,
                                                  keyword: controller.text,
                                                  onTap: () {
                                                    _openResult(item);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                  ),

                                  // ========================
                                  // Load More
                                  // ========================
                                  if (hasMore[type] ?? false)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 8,
                                      ),
                                      child: FilledButton.tonalIcon(
                                        onPressed: loadingMore[type] == true
                                            ? null
                                            : () {
                                                loadMore(type);
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
                                              ? 'در حال دریافت...'
                                              : 'نمایش بیشتر',
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
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        // ==================================
                        // Bottom Space
                        // ==================================
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
